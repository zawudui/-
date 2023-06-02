%本函数可以完成N*N任意个水平的两因素被试内方差分析（两因素重复测量方差分析），基于rm_anova2函数，此函数，本函数只是提高了其易用性，未改变其计算方法和性能等。
% 注意，要使用此函数，除需要将本函数加入matlab的路径，也需要将rm_anova2加入matlab工作路径。如果你获得本函数时没有同时获取rm_anova2函数，可通过以下地址下载：https://www.mathworks.com/matlabcentral/fileexchange/6874-two-way-repeated-measures-anova

% 作者：李经纬，邮箱：lijw98@outlook.com，有问题可邮件联系。祝各位显著。

% 使用说明：
%{
输入参数：
数据：在本函数中，仅需要输入一个三维的数据：
anovadata：被试*条件1*条件2
即如果有十个被试，条件一有两个水平，条件二有三个水平，那么size(anovadata)为10*2*3

可选输入参数：
condition：为两个因素的名字，如可命名为condition={'tiaojian1','tiaojian2'} 。如果不对其进行设定，两个因素自动命名为'Factor1'和'Factor2'

输出参数：
本函数输出三个值，分别为 主效应1的p值 主效应2的p值 交互作用的p值
	%}

function [pf1, pf2, pinter] = ljw_2way_rmanova(anovadata, condition)

    if (~exist('condition', 'var'))
        FACTNAMES = {'Factor1', 'Factor2'}; % 如果未出现该变量，则对其进行赋值
    end

    numsub = size(anovadata, 1);

    %重新整理数据，变为可用rm_anova2处理的形式
    tobesta = [];

    for ii = 1:size(anovadata, 3)
        tobesta = [tobesta; anovadata(:, :, ii)];
    end

    tobestat = [];

    for ii = 1:size(anovadata, 2)
        tobestat = [tobestat; tobesta(:, ii)];
    end

    F1_con = size(anovadata, 2); %F1自变量水平数
    F2_con = size(anovadata, 3); %F2自变量水平数
    total_con = F1_con * F2_con; %实验条件总数

    S = repmat([1:numsub], 1, total_con).';
    % F1和F2 为自变量的水平，被试变量
    F1 = sort(repmat([1:F1_con], 1, numsub * F2_con)).';
    F2 = repmat(sort(repmat([1:F2_con], 1, numsub)), 1, F1_con).';

    %统计
    stats = rm_anova2(tobestat, S, F1, F2, FACTNAMES);
    pf1 = stats{2, 6};
    pf2 = stats{3, 6};
    pinter = stats{4, 6};
end
