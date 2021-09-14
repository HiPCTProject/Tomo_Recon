function y=inputwdefault(question,default)

lim=10;

if length(default)>lim
	y=input(sprintf('%s      :\n[%s]\n',question,default),'s');
else
	y=input(sprintf('%s      : [%s] ',question,default),'s');
end

if isempty(y)
	y=default;
end
