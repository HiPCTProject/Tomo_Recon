% function [rb,re,cb,ce]=getcorners(a1,varargin)
%
% used to get pixel-coordinates from a region
% returns rb: begin row in a1
%	  re: end row
% 	  cb: begin column
% 	  ce: end column
% displays the image a1, turned by 90 degrees (Matlab display)
% region is indicated interactively by giving two end-points of a diagonal
% if a coordinate is outside the image, the nearest edge of the image is returned
%
% a1 contains the image
% varargin contains eventually a textstring or two to be displayed
%
% uses ginput
%
% origin: Peter Cloetens ESRF, modified by Paul Tafforeau ESRF

function [rb,re,cb,ce]=getcorners_paul(a1,varargin)

switch nargin

case 1
text1='Indicate top-left corner';
text2='Indicate bottom-right corner';

case 2
text1=varargin{1};
text2=text1;

case 3
text1=varargin{1};
text2=varargin{2};

end % switch on nargin

figure;imshow(a1',[]);
colormap(gray)
title(text1)
tl=round(ginput(1));
title(text2)
br=round(ginput(1));
title('')

rb=max(min([tl(1) br(1)]),1);
re=min(max([tl(1) br(1)]),size(a1,1));
cb=max(min([tl(2) br(2)]),1);
ce=min(max([tl(2) br(2)]),size(a1,2));
