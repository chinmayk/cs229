function res=rankedEvalCF(predictedPref,truePref,K,coeff)
% A ranked evaluation metric for collaborative filtering 
% based on the measure in Heckerman et al. (2000).
%
% FUNCTION res=rankedEvalCF(predictedPref,truePref)
%
% predictPref  A vector representing the predicted preferences
% 
% truePref     A vector representing the true preferences of 
%              the items: truePref(i) is the preference of item i.
%              If truePref(i)=0 then no preference is reported.
%
% Guy Lebanon, July 2003

if nargin<=2,
    K=20;
end
if nargin<=3,
    coeff=0.3;
end

[Y,I]=sort(predictedPref);
if K>length(Y), 
    K=length(Y);
end
I=fliplr(I);
rankedList=I(1:K);
% create an exponentially decaying probability vector
pos=1:K;probs=2.^(- coeff * pos);probs=probs/sum(probs);
% evaluate expected true value of chosen item
res=sum(truePref(rankedList).*probs);