u=[1 1;2 2; 3 3; 4 4; 5 5];
v=[1 3;2 3; 5 3; 6 3];
w=[1 4;2 3; 3 2; 4 2;5 3; 6 2];
x=[1 5;2 4; 4 2; 5 5];
us=cell(1,1);
vs=cell(1,1);
ws=cell(1,1);
xs=cell(1,1);
us{1}=u;us{2,1}=v;
vs{1}=w;vs{2,1}=x;

simMat=memoryBasedModels(us,vs,1,1,6);

a=[1 2 3 4 5 1];
b=[3 3 1 1 3 3];
c=[4 3 2 2 3 2];
d=[5 4 1 2 5 1];

sum( (a-mean(a)).*(b-mean(b)) ) / sqrt(5*var(a)*5*var(b))
dot(a,b)/(norm(a)*norm(b))