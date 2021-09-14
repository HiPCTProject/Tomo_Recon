% function [val,r,c]=min2(mat)

function [val,r,c]=min2(mat)

[n,m]=size(mat);
[val,b]=min(mat(:));
c=floor(b/n)+1;
r=b-n*(c-1);
if r==0
	r=n;
end
