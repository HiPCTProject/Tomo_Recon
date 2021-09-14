% origin Paul Tafforeau ESRF 2020


function clean_scan_series (radix)


cmd=sprintf('rm -rf %s/*OAR*',radix)
system(cmd)
cmd=sprintf('rm -rf %s/*oar*',radix)
system(cmd)
cmd=sprintf('rm -rf %s/*machine*',radix)
system(cmd)
cmd=sprintf('rm -rf %s/*previous*',radix)
system(cmd)
cmd=sprintf('rm -rf %s/*pyhst*',radix)
system(cmd)
cmd=sprintf('rm -rf %s/*Current_Scan_Status.info*',radix)
system(cmd)
cmd=sprintf('rm -rf %s/*.params',radix)
system(cmd)
%cmd=sprintf('rm -rf %s/*mean*',radix)
%system(cmd)

end
