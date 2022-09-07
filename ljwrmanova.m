%重复测量方差分析函数


%说明：
%{
该函数可以完成任意个条件的被试内方差分析（重复测量方差分析），其需要的数据结构为：
anovadata：被试*条件，即每一行为每个被试的所有条件，每一列为每种条件下的所有被试，例如100个被试3个条件即为100*3
condition：元胞数组，需要和条件数相同
multicompare：0或1，如果为0的话只会计算p值、f值和table，如果为1的话会画图，包括每个被试各条件之间的点图及连线，柱状图和error bar。默认为0
	%}

function [pvalue,tbl,fvalue]=ljwrmanova(anovadata,condition,multicompare)
	if(~exist('multicompare','var'))
		multicompare= 0;  % 如果未出现该变量，则对其进行赋值
	end
	%方差分析
	measure3=table([1:size(condition,2)]', 'VariableNames', {'value'});
	dataword=[];
	for ii=1:size(condition,2)%构成重复测量方差分析的数据结构
		dataword=[dataword,'anovadata(:,',num2str(ii),'),'];
	end
	eval(['tabl_temp=table(',dataword,'''VariableNames'', condition)'])%构成一个数据表
	
	%构造rm3
	comparelabel=join([condition(1),'-',condition(end),'~1'])
	newcomparelabel= strrep(comparelabel,' ','') 
	tword=join(['rm3=fitrm(tabl_temp,''',newcomparelabel,''',''WithinDesign'', measure3)']);
	rm3word=strrep(tword,' ','')
	eval(cell2mat(rm3word));
	
	tbl_ranova_pbp=ranova(rm3);
	pvalue=table2array(tbl_ranova_pbp(1, 5)); % save the point-by-point p value from anova
	fvalue=table2array(tbl_ranova_pbp(1, 4)); % save the point-by-point F value from anova
	tbl = multcompare(rm3,'value');

	%以下是画图（如果muticompare等于1，则运行以下代码，即进行画图）
	if multicompare==1
		tbl = multcompare(rm3,'value')	
		x=[];
		for i=1:length(condition)%生成一个横轴矩阵
			x(i,:)=i.*ones(1,size(anovadata,1));
		end
		%准备画图变量，将数据转换为相互对应的一维
		plotx=reshape(x,1,numel(x));
		ploty=reshape(anovadata',1,numel(anovadata));%两个数组结构不同，重构的时候要转置其中一个
		%依次画被试数量个点和折线图
		color=[];
		figure;hold on;
		for i=1:length(condition):length(plotx)
			tindex=[];%构造一个指示变量，指示每次画图时对应的x y的位置，每次都是“条件数”个
			for ii=1:length(condition)
				tindex=[tindex,i+ii-1];
			end
			color=[randi([1,255]),randi([1,255]),randi([1,255])]/255;%随机一个颜色
			pl=line(plotx(tindex),ploty(tindex));
			pl.Color =color;
			scatter(plotx(tindex),ploty(tindex),[],color,'filled')%点图
		end
		%画条形图和errorbar
		bar(mean(anovadata,1),'facecolor','none');
		err=sqrt((std(anovadata).^2)*size(anovadata,1)/(size(anovadata,1)-1));%计算error
		ploterrorbar=errorbar(mean(anovadata,1),err,'o');
		ploterrorbar.Color='k';
		% 设置横坐标
		xticks(1:length(condition))
		xticklabels(condition)
	end%画图结束
end%函数结束