% function to create an ellipsoid mask (or a circle)
%
% mask = create_circular_mask(posx,posy,radius,diming)
%
% Parameters include:
%
% posx and posy : position of the center of the circle
%
% radius        : radius of the circle
%
% diming        : dimension of the imge (or canvas) the circle will be
%               drawn in (set in brackets [])
%

function mask = create_circular_mask(posx,posy,radius,diming)

[W,H] = meshgrid(1:diming(2),1:diming(1));
mask= sqrt((W-posx).^2 + (H-posy).^2) <= radius;

end
