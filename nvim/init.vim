for f in sort(split(glob('~/.config/nvim/enabled/*.vim'),'\n'))
	exe 'source' f
endfor

