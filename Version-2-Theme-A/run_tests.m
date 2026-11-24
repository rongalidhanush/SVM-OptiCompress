function results=run_tests()
root=setup(); results=runtests(fullfile(root,'tests'));
disp(table(results)); assertSuccess(results);
end
