#!/bin/tcsh -f

set tot = `wc grid_theta_table.txt | awk '{print $1}'`

@ num = 1

while ($num <= $tot)
    set grid_num = `awk '{if (NR == '$num') print $1}' grid_theta_table.txt`
    set theta = `awk '{if (NR == '$num') print $2}' grid_theta_table.txt`

    set costh = `echo $theta | awk '{print cos($1/180.*3.141592)}'`

    echo $grid_num $theta $costh

    echo MATRIX $costh | awk '{printf("%s*%lf\n", $1, $2)}' > ! exp.txt
    /bin/mv -f BAT_alldet_grid_"$grid_num".rsp BAT_alldet_grid_"$grid_num"_org.rsp
    
    ftcalc BAT_alldet_grid_"$grid_num"_org.rsp+1 BAT_alldet_grid_"$grid_num".rsp MATRIX '@exp.txt' clobber=yes

    @ num++
end
