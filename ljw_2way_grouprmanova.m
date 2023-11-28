%本函数可以完成多组数据的，N组*N个任意个水平的分组的两因素方差分析（分组的两因素重复测量方差分析），基于matlab自带的ranova函数。

% 作者：李经纬，邮箱：lijw98@outlook.com，有问题可邮件联系。祝各位显著。

% 使用说明：
%{
输入参数：
数据：在本函数中，仅需要输入一个三维的数据：
anovadata：被试*分组*条件
即如果两组各有十个被试，条件有两个水平，那么size(anovadata)为10*2*2，如果条件有三个水平，则为10*2*3

输出参数：
本函数输出四个值，分别为 分组的主效应统计p值，条件间的主效应统计p值，交互作用的p值，统计表
注意：输入数组必须为被试*分组*条件
groupname是可选的，可以输入groupname={'aa','bb','cc'},也可以不输入
	%}

function [p_group, p_cond, p_inter, ranovatbl] = ljw_2way_grouprmanova(anovadata, groupname)

    % 如果未输入groupname(组名称)变量，则自动生成一个

    if (~exist('groupname', 'var'))
        groupname = {};
        for ii = 1:size(anovadata, 2)
            textleft = ['groupname{', num2str(ii), '}'];
            textright = ['group', num2str(ii)];
            eval([textleft, '=', '"', textright, '"',';']); % 如果未出现该变量，则对其进行赋值,默认第二个维度为分组数量
        end
    else
        groupname = cellfun(@string, groupname, 'UniformOutput', false);
    end

    %将数据构建为一个几列分别为 group，cond1,cond2,cond3...的table
    %%首先构建第一列，为sub*group行
    groupnum = size(anovadata, 2);
    subnum = size(anovadata, 1);

    for ii = 1:groupnum
        tgroupname = groupname{ii};
        group(((ii - 1) * subnum + 1):ii * subnum) = tgroupname;
    end

    group = group';

    %%接下来构建后面的几列，即每组被试重复的条件
    data = [];

    for ii = 1:groupnum
        adddata = squeeze(anovadata(:, ii, :));
        data = [data; adddata];
    end

    %将group和data合并起来，建立table
    t = table;
    t.group = group;

    for ii = 1:size(anovadata, 3)
        tname = ['condition', num2str(ii)];
        tcolumnname = ['data(:,', num2str(ii), ')'];
        eval(['t.', tname, '=', tcolumnname, ';']);
    end

    %使用fitrm拟合
    condition = [1:size(anovadata, 3)]';
    rm = fitrm(t, ['condition1-condition', num2str(size(anovadata, 3)), '~group'], 'WithinDesign', condition);

    %两因素方差分析
    ranovatbl = ranova(rm);
    p_cond = ranovatbl{1, 5};
    p_inter = ranovatbl{2, 5};

    %组间分析
    p_group=anova1(squeeze(mean(anovadata(:,:,:),3)),[],'off');
    
end
