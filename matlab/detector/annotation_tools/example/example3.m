function example3(a)

disp(sprintf('Press \''<-\'' and \''->\'' to navigate the H3D data set'));
disp(sprintf('Press \''g\'' to go to a given annotation. '));
disp(sprintf('Press \''SPACE\'' and drag a rectangle over a body part of a person to find similar patches'));
disp(sprintf('See the comments inside browse_annotations.m for additional commands'));
disp(sprintf('Press \''ESC\'' to exit. '));

browse_annotations(a);
