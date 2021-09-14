function im = invpolar2(pim,sl)
% im = invpolar2(pim,sl)
%
% Inverse polar transform of an polar image. Can be used together with
% Peter Kovesis polartrans found on the Matlab Fileshare.
%
% Input:
%   pim         - image in polar coordinates with radius increasing down
%                 the rows and theta along the columns
%   sl          - side length of the output image
%
% Output:
%   im         - image in cartesian coordinates
%
% 17/10/2006
% Allan Lyckegaard, Department of Material Research (AFM),
% Risoe National Laboratory, Denmark. www.riseo.dk/afm
%
% Thanks to:
% Erik M. Lauridsen, AFM - Risoe, Denmark, www.riseo.dk/afm
% Greg Johnson, ESRF, France, and University of Manchester, UK, www.man.ac.uk
% Paul Tafforeau, ESRF, France, www.esrf.fr

% sl = side length of the output image

rmax = sqrt(2*(sl-1)^2);
% get size
ntheta = size(pim,2);
nrad = size(pim,1);

% fill out NaN part of pim to avoid NaNs in interp2 result - this is a hack!
smask = sum(isnan(pim),1);
for c=1:size(pim,2)
    r = nrad-smask(c);
    %rmax = max(r+3,nrad);
    %pim(r:rmax,c)=pim(r,c);
    pim(r:end,c)=pim(r,c);
end

% radius - determine start radius
if mod(sl,2)==0
    rad0 = 0.5;
else
    rad0 = 0;
end

% radius vector - include one extra radius qua interp2
rad = linspace(rad0,rmax,nrad);

% theta vector - include leap at 0/2pi
theta = linspace(0,2*pi,ntheta+1);

% make R and T lookup tables
[R,T] = meshgrid(rad, theta);

% make grid for output image
%[Xmat,Ymat] = meshgrid(1:sl/(rmax*sqrt(2)):sl,sl:-sl/(rmax*sqrt(2)):1);
[Xmat,Ymat] = meshgrid(linspace(1,(rmax*sqrt(2)),sl),linspace((rmax*sqrt(2)),1,sl));

% center the grid
Xcart = Xmat - max(Xmat(:)/2+0.5);
Ycart = Ymat - max(Ymat(:)/2+0.5);

% cart grid -> polar grid
[invT,invR] = cart2pol(Xcart,Ycart);

% include leap at 0/2pi adn extra radius in pim
ext_pim = ([pim, pim(:,end)])';%; pim(end,:), pim(end)])';

im = interp2(R,T,ext_pim,invR,invT+pi,'*linear');
im = imrotate(im,180);
%imshow(im,[]),shg