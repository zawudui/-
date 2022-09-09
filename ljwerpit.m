%处理数据时查看ERP的代码
%在处理数据时查看该被试的波形图代码：总体思路是利用EEG结构体中的数据，按照不同的marker做不同条件下的波形图
%EEG为使用eeglab导入脑电数据后生成的变量，condition为各个条件，为元胞数组，chan为电极，colour为各条件下画图使用的颜色

	
function ljwerpit(EEG,condition,chan,colour)
	figure;hold on;
	marker={EEG.event.type};%需要先拿出EEG.event.type来
	for j =1:size(condition,1)
		ind=find(strcmp(marker, condition{j}));%对应marker 的位置
		plot(EEG.times, squeeze(mean(EEG.data(chan,:,ind),3)),colour{j});%现在横轴是times，纵轴是对应电极点某一条件下所有trial的平均值
	end
	legend(condition);set(gca,'YDir','reverse'); %负极朝上
	title(EEG.chanlocs(chan).labels);
end