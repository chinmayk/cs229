/*-----------------------------------------------------
  Functions for predicting user's prefernce based on 
  the memeory based models defined in Breese et al.

  - Guy Lebanon, July 2003.
  ------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "mex.h"

#define EPS 0.00001

/*------------------------------------------------- 
  a structure that represents a (single) vote on a
  specific item by a specific user. 
  --------------------------------------------------*/
typedef struct vote {
  int itemID;
  int value;
} vote;

typedef struct user {
  int numItems;
  int defaultVote;
  int numVotes;
  vote* votes;
} user;


/*-------------------------------------------------
  Computes the average vote for a specific user.
  If defaultVote>0, the unvoted items get a vote
  of defaultVote.
  -------------------------------------------------*/
double AverageVote(const user u)
{
  int i;
  double res=0;
  for (i=0;i<u.numVotes;i++) 
    res += u.votes[i].value;
  if (u.defaultVote>0)
    return (res+u.defaultVote*(u.numItems-u.numVotes))
      /( (double)u.numItems);
  else return res / ( (double)u.numVotes);
}

/*-------------------------------------------------
  Computes the sum of squared votes for a specific user.
  If defaultVote>0, the unvoted items get a vote
  of defaultVote.
  -------------------------------------------------*/
double SumSquaresVote(const user u)
{
  int i;
  double res=0;
  for (i=0;i<u.numVotes;i++) 
    res += pow(u.votes[i].value,2);
  if (u.defaultVote>0)
    return res+pow(u.defaultVote,2)*(u.numItems-u.numVotes);
  else return res;
}
/*-------------------------------------------------
  Computes the variance vote for a specific user.
  If defaultVote>0, the unvoted items get a vote
  if defaultVote.
  Note: This is non-normalized (not divided by the 
  number of votes).
  -------------------------------------------------*/
double VarianceVote(const user u)
{
  int i;
  double avg=AverageVote(u);
  double res=0;
  for (i=0;i<u.numVotes;i++) 
    res += pow(u.votes[i].value-avg,2);
  if (u.defaultVote>0)
    return res + pow(u.defaultVote-avg,2) * 
      (u.numItems-u.numVotes);
  else return res;
}

/*---------------------------------------------------
  Computes the Pearson's correlation between two users
  (equation (2) at Breese et al.). 
  If defaultVote>0, the unvoted items get a vote
  defaultVote.

  IMPORTANT:
  The votes of users u,v are assumed to be sorted 
  according to itemID.
  -----------------------------------------------------*/
double Correlation(const user u, const user v)
{
  double avg1,avg2,cov=0,var1=0,var2=0;
  int i=0,j=0,currID1,currID2,intersectionSize=0,nonUnionSize;
  avg1=AverageVote(u); avg2=AverageVote(v);
  var1=VarianceVote(u);var2=VarianceVote(v);
  while (1) {
    if (i>=u.numVotes || j>=v.numVotes) break;
    currID1=u.votes[i].itemID;
    currID2=v.votes[j].itemID;
    if (currID1<currID2) {
      if (v.defaultVote>0)
	cov += (u.votes[i].value-avg1)*(v.defaultVote-avg2);
      i++;
    } else if (currID1>currID2) {
      if (u.defaultVote>0)
	cov += (u.defaultVote-avg1)*(v.votes[j].value-avg2);
      j++; 
    } else { /* The two items are equal */
      cov += (u.votes[i].value-avg1)*(v.votes[j].value-avg2);
      i++; j++; intersectionSize++;
    }
  }
  if (u.defaultVote>0) {/* add default vote to unvoted items*/
    if (i<u.numVotes)
      for (;i<u.numVotes;i++) cov += (v.defaultVote-avg2)*(u.votes[i].value-avg1);
    if (j<v.numVotes)
      for (;j<v.numVotes;j++) cov += (u.defaultVote-avg1)*(v.votes[j].value-avg2);
    nonUnionSize = u.numItems - u.numVotes - v.numVotes + intersectionSize;
    cov += nonUnionSize*(u.defaultVote-avg1)*(v.defaultVote-avg2);
  }

  if (cov == 0)
    return cov;
  else if (var1==0 || var2==0)
    return cov/fabs(cov);
  else 
    return cov / sqrt(var1 * var2);
}
/*--------------------------------------------------------------
  Vector similarity between two users (equation (3) in Breese 
  et al.). If defaultVote>0, the unvoted items get a vote
  defaultVote.

  IMPORTANT:
  The votes in user1,user2 are assumed to be sorted 
  according to itemID.
  ---------------------------------------------------------------*/
double VectorSimilarity(const user u, const user v) 
{
  double normU,normV,dotProd=0;
  int i=0,j=0,currID1,currID2,intersectionSize=0,nonUnionSize;
  normU=sqrt(SumSquaresVote(u));normV=sqrt(SumSquaresVote(v));
  while (1) {
    if (i>=u.numVotes || j>=v.numVotes) break;
    currID1=u.votes[i].itemID;
    currID2=v.votes[j].itemID;
    if (currID1<currID2) {
      if (v.defaultVote>0)
	dotProd += u.votes[i].value * v.defaultVote;
      i++;
    } else if (currID1>currID2) {
      if (u.defaultVote>0)
	dotProd += v.votes[j].value * u.defaultVote;
      j++;
    } else { /* The two items are equal */
      dotProd += u.votes[i].value * v.votes[j].value;
      i++;j++; intersectionSize++;
    }
  }
  if (u.defaultVote>0) {/* add default vote to unvoted items*/
    if (i<u.numVotes)
      for (;i<u.numVotes;i++) dotProd += u.votes[i].value * v.defaultVote;
    if (j<v.numVotes)
      for (;j<v.numVotes;j++) dotProd += v.votes[j].value * u.defaultVote;
    nonUnionSize = u.numItems - u.numVotes - v.numVotes + intersectionSize;
    dotProd += nonUnionSize * u.defaultVote * v.defaultVote;
  }
  return dotProd / (normU*normV);
}

/*----------------------------------------------------------
  Case amplification weight transform (section 2.2.3 in Breese
  et al.).
  -----------------------------------------------------------*/
double CaseAmplification(const double weight, const double rho) 
{
  if (weight >= 0) return pow(weight,rho);
  else return - fabs(pow(weight,rho));
}

/*------------------------------------------------------------
  Computes memory based similarity of one user (u) to several 
  (vsLen) other users (stored in vs). The result will be stored
  in res, which need to be pre-allocated before function call.
  -------------------------------------------------------------*/
void
computeSimilarityOne2Many(const user u, const user* vs, int vsLen, 
			  int method, double* res)
{
  int i;
  for (i=0;i<vsLen;i++) {
    switch(method) {
    case 1:
      res[i]=Correlation(u,vs[i]);
      break;
    case 2:
      res[i]=VectorSimilarity(u,vs[i]);
      break;
    default:
      res[i]=-1;
      break;
    }
  }
}


/*------------------------------------------------------------
  Computes memory based similarity between users us 
  to users vs. The result will be stored
  in res, which need to be pre-allocated before function call.
  -------------------------------------------------------------*/
void
computeSimilarityMany2Many(const user* us, int usLen, 
			   const user* vs, int vsLen, 
			   int method, double* res)
{
  int i,j;
  for (i=0;i<usLen;i++) {
    for (j=0;j<vsLen;j++) {
      switch(method) {
      case 1:
	res[j*usLen+i]=Correlation(us[i],vs[j]);
	break;
      case 2:
	res[j*usLen+i]=VectorSimilarity(us[i],vs[j]);
	break;
      default:
	res[j*usLen+i]=-1;
	break;
      }
    }
  }
}

void FreeUsers(user* u, int len) {
  int i;
  for (i=0;i<len;i++) mxFree(u[i].votes);
  mxFree(u);
}

/*----------------------------------------------------------------------
  The input arguments are
  user1, user2, similarity method, defaultVote, numItems.

  Each of the first input arguments have to be a 1-Dim column cell arrays 
  that represents the votes of the train users and the test users.
  Each cell entry representes votes of a specific user in the following
  format:
  itemID vote
  itemID vote
  .
  .
  .

  The last three input arguments are scalars reprsenting the method
  of computing the similarity, the defaultVote (applies if >0) and 
  the total number of distinct items.
  -----------------------------------------------------------------------*/
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
  int usSz, vsSz,i,j,simMethod;
  user* us, *vs;
  double* res, *matlabVotes;

  /* Check number of input and output arguments */
  if (nrhs != 5) mexErrMsgTxt("Five input arguments required");
  if (nlhs != 1) mexErrMsgTxt("One output argument required");
  if ( ! mxIsCell(prhs[0]) || ! mxIsCell(prhs[1]))
    mexErrMsgTxt("First two input arguments have to be cell arrays");

  usSz = mxGetM(prhs[0]); 
  vsSz = mxGetM(prhs[1]);
  simMethod = mxGetScalar(prhs[2]);

  /* read the two users into struct arrays */
  us = mxCalloc(usSz,sizeof(user));
  for (i=0;i<usSz;i++) {
    us[i].defaultVote = mxGetScalar(prhs[3]);
    us[i].numItems = mxGetScalar(prhs[4]);
    us[i].numVotes = mxGetM(mxGetCell(prhs[0],i));   
    matlabVotes = mxGetPr(mxGetCell(prhs[0],i));
    us[i].votes = mxCalloc(us[i].numVotes,sizeof(vote));
    for (j=0;j<us[i].numVotes;j++) {
      us[i].votes[j].itemID = (int)matlabVotes[j];
      us[i].votes[j].value  = (int)matlabVotes[j+us[i].numVotes];
    }
  }
  vs = mxCalloc(vsSz,sizeof(user));
  for (i=0;i<vsSz;i++) {
    vs[i].defaultVote = mxGetScalar(prhs[3]);
    vs[i].numItems = mxGetScalar(prhs[4]);
    vs[i].numVotes = mxGetM(mxGetCell(prhs[1],i));   
    matlabVotes = mxGetPr(mxGetCell(prhs[1],i));
    vs[i].votes = mxCalloc(vs[i].numVotes,sizeof(vote));
    for (j=0;j<vs[i].numVotes;j++) {
      vs[i].votes[j].itemID = (int)matlabVotes[j];
      vs[i].votes[j].value  = (int)matlabVotes[j+vs[i].numVotes];
    }
  }
  /* compute the similarities and store it in the output argument */
  plhs[0] = mxCreateDoubleMatrix(usSz,vsSz,mxREAL);
  res = mxGetPr(plhs[0]);
  computeSimilarityMany2Many(us,usSz,vs,vsSz, simMethod, res);
  FreeUsers(us, usSz);
  FreeUsers(vs, vsSz);
  return;
}
