/*-----------------------------------------------------
  Functions for predicting user's prefernce based on 
  the PD model in Pennock et al.

  - Guy Lebanon, July 2003.
  ------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "mex.h"

double computePosterior(double* pred,int numUsers,int numValues,
			const double* probPerson,const double* usersVote,double tau)
{
  int i,j;
  double meanPred=0,sumVal=0,*Z=mxCalloc(numValues,sizeof(double));

  /* compute normalization factors */
  for (i=1;i<=numValues;i++)
    for (j=1;j<=numValues;j++)
      Z[i-1] += exp(-tau * pow(j-i,2) );

  /* compute the posterior probabilities */
  for (i=1;i<=numValues;i++) {
    for (j=0;j<numUsers;j++) {
      if (usersVote[j]==0) 
	pred[i-1] += probPerson[j] / numValues;
      else
	pred[i-1] += probPerson[j] *
	  exp(-tau * pow(usersVote[j]-i,2) ) / Z[(int)usersVote[j]-1];
    }
  }

  /* compute the mean predicted value */
  for (i=0;i<numValues;i++) 
    meanPred += pred[i] * (i+1);

  mxFree(Z);
  return meanPred;
}

/*----------------------------------------------------------------------
  The input arguments are
  probPerson -  probability distribution over the users (column)
  usersVote  -  The votes of the users for the item in question 
                (column vector, 0 representing missing data)
  numValues  -  The number of possible preference values
  tau        -  The Gaussian parameter

  The output arguments is
  - a column vector representing the PD predicted preference for the item
  in question.
  - the mean prediction for the preference of the item in question
  -----------------------------------------------------------------------*/

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
  int numUsers, numValues;
  double* probPerson, *pred, *usersVote, tau, meanPred;

  /* Check number of input and output arguments */
  if (nrhs != 4) mexErrMsgTxt("Four input arguments required");
  if (nlhs != 2) mexErrMsgTxt("Two output argument required");

  numUsers   = (int)mxGetM(prhs[0]); 
  probPerson = mxGetPr(prhs[0]);
  usersVote  = mxGetPr(prhs[1]);
  numValues  = (int)mxGetScalar(prhs[2]);
  tau        = mxGetScalar(prhs[3]);

  plhs[0]    = mxCreateDoubleMatrix(numValues,1,mxREAL);
  pred       = mxGetPr(plhs[0]);
  meanPred   = computePosterior(pred,numUsers,numValues,probPerson,usersVote,tau);
  plhs[1]    = mxCreateDoubleScalar(meanPred);
  return;
}
