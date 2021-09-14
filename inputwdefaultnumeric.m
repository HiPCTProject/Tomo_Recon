function y=inputwdefaultnumeric(question,default)
  % modified version of inputwdefault for numbers

lim=10;

if length(default)>lim
	y=input(sprintf('%s      :\n[%s]\n',question,default));

else
	y=input(sprintf('%s      : [%s] ',question,default));
end

if isempty(y)
  y=eval(default);

end
