% function rm=interpolate(matrix,r,c)
% interpolates a matrix (or vector) r rows down and c columns to the right
% rm(i,j)=matrixcorrelate(i-r,j-c)
% the points which are out of the range of the original matrix are replaced
% by extrapolation
% uses bilinear interpolation

function rm=interpolate(matrix,r,c)
[n,m]=size(matrix);

%avg=mean2(matrix);

% number of rows lost
nl=ceil(abs(r));
% number of columns lost
ml=ceil(abs(c));


if (r>=0)&(c>=0)
	[X,Y]=meshgrid(1+ml-c:m-c,1+nl-r:n-r);
	%rm=[avg*ones(nl,m);avg*ones(n-nl,ml) interp2(matrix,X,Y,'*linear')];
    rm = [matrix(1,1)*ones(nl,ml) repmat(matrix(1,1:m-ml),nl,1);repmat(matrix(1:n-nl,1),1,ml) interp2(matrix,X,Y,'*linear')];
elseif (r<=0)&(c>=0)
	[X,Y]=meshgrid(1+ml-c:m-c,1-r:n-r-nl);
% 	rm=[avg*ones(n-nl,ml) interp2(matrix,X,Y,'*linear'); avg*ones(nl,m)];
    rm = [repmat(matrix(nl+1:end,1),1,ml) interp2(matrix,X,Y,'*linear'); matrix(n,1)*ones(nl,ml) repmat(matrix(n,1:m-ml),nl,1)];
elseif (r<=0)&(c<=0)
	[X,Y]=meshgrid(1-c:m-c-ml,1-r:n-r-nl);
% 	rm=[interp2(matrix,X,Y,'*linear') avg*ones(n-nl,ml); avg*ones(nl,m)];
    rm = [interp2(matrix,X,Y,'*linear') repmat(matrix(1+nl:end,m),1,ml); repmat(matrix(n,1+ml:end),nl,1) matrix(end,end)*ones(nl,ml)];
elseif (r>=0)&(c<=0)
	[X,Y]=meshgrid(1-c:m-c-ml,1+nl-r:n-r);
% 	rm=[avg*ones(nl,m); interp2(matrix,X,Y,'*linear') avg*ones(n-nl,ml)];
    rm = [repmat(matrix(1,ml+1:end),nl,1) matrix(1,m)*ones(nl,ml); interp2(matrix,X,Y,'*linear') repmat(matrix(1:n-nl,end),1,ml)];
end








