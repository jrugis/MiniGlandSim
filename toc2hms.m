function [hms] = toc2hms(t)
hd = t./3600;
h = floor(hd);
md = (hd-h)*60; 
m = floor(md);
s = round((md-m)*60);
hms = convertStringsToChars(string(h)+'h '+string(m)+'m '+string(s)+'s');
end
