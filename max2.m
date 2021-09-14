% function [val,r,c]=max2(mat)

function [val,r,c]=max2(mat)

[n,m]=size(mat);
[val,b]=max(mat(:));
c=floor(b/n)+1;
r=b-n*(c-1);
if r==0
	r=n;
end
