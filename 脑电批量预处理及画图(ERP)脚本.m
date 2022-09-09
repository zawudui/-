%{
	此脚本为脑电数据预处理及ERP画图批量处理所用的脚本，本脚本所用的函数基于matlab和开源工具箱EEGlab，其函数使用说明均可以在公开网站上找到，如有问题可自行搜索。
	也可联系: lijw98@outlook.com
%}

% 假设有20个被试，每个被试有三个条件分别为A B C
% 数据组织形式为：一个被试编号的文件夹里包含三种条件下的三个文件，文件名均命名为相应条件，其marker分别为16 20 50


	% 导入数据，将每种条件下的maker转换，然后合并成一个文件
	%{
		注意，使用以下这段代码时，需要改的有以下几个参数
		filename，需要改为存在原始数据的文件夹
		pop_loadbv 函数，对不同类型的数据可能有不同的导入函数，需要根据情况修改
		pop_chanedit 函数，需要修改文件路径至相应的eeglab文件夹
		pop_epoch 函数，需要修改marker（16 20 50等），根据数据修改
		pop_reref 函数，重参考的电极，根据实验设计和相关文献进行选择
	%}

	eeglab
	set(gcf,'HandleVisibility','off');%隐藏eeglab窗口
    condition={'A','B','C'}
	colour={'b','r','g'};
	for sub= 1:20 %被试循环
			filename=['D:\rawdata\',num2str(sub),'\','.cnt'];%设置文件的路径和名称，生成名为filename的路径和文件名变量
			EEG = pop_loadbv([filename]);%导入数据，注意，不同类型的数据有不同的导入函数，可以先使用EEGlab的import data手动操作，然后从EEG.history中找到相应代码，进行修改后批量处理
			EEG=pop_chanedit(EEG, 'lookup','C:\eeglab2022.0\\plugins\\dipfit\\standard_BEM\\elec\\standard_1005.elc');%电极定位，需要找到安装eeglab的文件夹，找到同名文件，替换路径即可
			EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'plotfreqz',1);%高通，滤掉0.1Hz以下的频率
			EEG = pop_eegfiltnew(EEG, 'locutoff',49,'hicutoff',51,'revfilt',1,'plotfreqz',1);%滤工频干扰
			EEG = pop_eegfiltnew(EEG, 'hicutoff',100,'plotfreqz',1);%滤掉100Hz以上的频率
			EEG = pop_epoch( EEG, {'16' '20' '50'}, [-1  2], 'epochinfo', 'yes');%分段，将evnet值为16 20 50的前1s到2s提取出来，删掉其他
			EEG = pop_rmbase( EEG, [-1000 0] ,[]);%基线校正，利用刺激开始前1000ms的波形的平均值进行基线校正
			for nummarker =1:length(EEG.event)%修改marker
				EEG.event(nummarker).type=strrep(EEG.event(nummarker).type,'16',cell2mat(condition(1)));%修改值为16的marker为条件1
                EEG.event(nummarker).type=strrep(EEG.event(nummarker).type,'20',cell2mat(condition(2)));%修改值为20的marker为条件2
                EEG.event(nummarker).type=strrep(EEG.event(nummarker).type,'50',cell2mat(condition(3)));%修改值为50对marker为条件3
			end
			EEG = pop_reref(EEG, [13 19]);%重参考，根据EEG.chanloc中的电极位置信息来确定选择哪些电极来进行重参考
			mkdir(['D:\markerchanged\' num2str(sub)]);%创建文件夹,防止下面一句报错
			EEG = pop_saveset( EEG, 'filename',[num2str(sub),'.set'],'filepath', ['D:\markerchanged\' num2str(sub)]);%！！如果文件夹不存在会报错,可以修改保存的路径和文件名
		close all
	end%被试循环结束
	
	% % 拼合数据，如果同一个被试有很多个条件，可以用以下的代码来实现拼合
		eeglab;
		mkdir('D:\merged\');%创建文件夹
		filepath='D:\markerchanged\' %可以修改路径
		savefilepath='D:\merged\' %可以修改路径
		eeg=struct;
		for sub=1:20%被试循环
			for j=1 : 3 %条件循环
				EEG = pop_loadset('filename', [condition{j} '.set'] ,'filepath', [filepath num2str(sub)]);%载入文件
				eval(['eeg',num2str(j),'=','EEG']);
			end
			EEG1=pop_mergeset(eeg1,eeg2);
			if length(condition)>=3%如果有三种以上条件，下面的代码可以多次拼合
				for tt=3:length(condition)
					eval(['EEG1=pop_mergeset(EEG1,eeg',num2str(tt),')']);%拼合数据，在循环内重复拼合
				end
			end
			EEG = pop_saveset( EEG1, 'filename',[num2str(sub) '.set'],'filepath', savefilepath);
		end


	%剔除坏段，做ica
		%剔除坏段
		chan=15;
		eeglab
		set(gcf,'HandleVisibility','off');%隐藏eeglab窗口
		for sub=1:20
			EEG = pop_loadset('filename', [num2str(sub) '.set'] ,'filepath', 'D:\merged\');%载入文件
			pop_eegplot(EEG , 1, 1, 1);%显示波形，剔除坏段
			ljwerpit(EEG,condition,chan,colour)%该函数为自编函数，目的是建议地呈现各条件的ERP波形，需要把该函数加入matlab路径内才能调用，
			disp('剔除坏段后按任意键继续')
			pause
			EEG = pop_saveset(EEG, 'filename',[num2str(sub) '.set'],'filepath', 'D:\trialrejected\');%注意保存的路径要存在
			close all
		end
		%ICA
		for sub=1:20
			EEG = pop_loadset('filename', [num2str(sub) '.set'] ,'filepath', 'D:\trialrejected\');%载入文件
			EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on');%跑ICA
			EEG = pop_saveset(EEG, 'filename',[num2str(sub) '.set'],'filepath', 'D:\runica\');%注意保存的路径要存在
		end

	
	%根据ica结果剔除ica成分，一般剔除眼动、肌电、心电等
		eeglab
		set(gcf,'HandleVisibility','off');%隐藏eeglab窗口
		for sub=1:20
			EEG=pop_loadset('filename',[num2str(sub) '.set'] ,'filepath', ['D:\runica\']);%载入文件
			EEG = pop_iclabel(EEG, 'default');%显示带标签的ica
			figure;
			pop_selectcomps(EEG, [1: size(EEG.icaweights,1)] );%选择标记要剔除的成分
			pause%暂停，在图形界面中选择剔除的成分后继续
			disp('选择要剔除的成分后，按任意键继续')
			rejcombianhao=find(EEG.reject.gcompreject);%提出要剔除的成分的标号
			EEG = pop_subcomp( EEG,rejcombianhao, 0);%剔除标记的成分
			EEG = pop_saveset( EEG, 'filename',[num2str(sub) '.set'],'filepath', 'D:\icarejected\');%！！如果文件夹不存在会报错;%保存剔除成分后的数据
			close all
		end


% --------------------------------------------------------------------------------
%至此，预处理已经结束，接下来是画图工作
	%挑选各条件，构建画图数据结构体
	eeglab;eeg=struct;
	for sub= 1:20
		EEG1=pop_loadset('filename',[num2str(sub) '.set'] ,'filepath', ['D:\icarejected\']);%载入文件为EEG1
		EEG1 = pop_eegfiltnew(EEG1, 'locutoff',1,'plotfreqz',1);%滤掉1hz的低频
		EEG1 = pop_eegfiltnew(EEG1, 'hicutoff',30,'plotfreqz',1);%滤掉30Hz以上的高频，因为对一般ERP来说，1-30Hz是较为合适的滤波频段，可以画出较为漂亮的波形
		for j=1:length(condition)
			EEG = pop_selectevent( EEG1, 'type',condition{j},'deleteevents','off','deleteepochs','on','invertepochs','off');%挑选特定marker（条件）的试次，拿出来做进一步处理
			data(sub,j,:,:)=squeeze(mean(EEG.data,3));%subj*condition*channel*timepoints，形成一个四维结构体，包含所有被试所有条件所有电极的信息，可以随时调用和画图
		end
		close all
	end
		tepoch=EEG.times;chanloc=EEG.chanlocs;%将分段的时间信息和电极位置信息分别保存在tepoch和chanloc两个变量里
		EEG=[];EEG.times=tepoch;EEG.chanlocs=chanloc; %重新定义结构体EEG，只把时间信息和电极位置信息保留在EEG中，留作后面画图备用
		save 'D:\allsubdata\allsubdata.mat'  data EEG  condition  colour %保存数据
		
	
	%画波形图
		figure;hold on;
		sub=[1:20];
		colour={'b','r','g'};
		set(gca,'YDir','reverse'); %负极朝上
		for j=1:3
			plot(EEG.times, squeeze(mean(data(sub,j,chan,:),1)),colour{j}); % 所有被试在该电极点、该条件下的平均波形
		end	
		legend(condition);
		title(EEG.chanlocs(chan).labels);
		xlabel('Latency (ms)','fontsize',16); %% name of X axis
		ylabel('Amplitude (uV)','fontsize',16);  %% name of Y axis
	
	%统计及画图，对所有时间点的三个条件的脑电值进行统计
		for i=1:size(data,4)%所有时间点的循环
			x=squeeze(data(:,:,chan,i));
			pvalue=ljwrmanova(x);%该函数为自编的,如何使用请参见github库内该函数
			allpvalue(i)=pvalue;
		end

		%随后在波形图上画线表示显著
		[~,adjp] = fdr(allpvalue,0.01);%多重比较校正，得到校正后的p值
		hold on;
		psig=adjp;
		psig(psig>0.05)=-1;psig(psig>=0&psig<=0.05)=1;psig(psig==-1)=0;
		y=mean(data,'all').*ones(sum(psig),1);%计算出有多少个画图的点，并把它的值设为矩阵的均值
		scatter(EEG.times(psig==1),y,'filled');%x轴的显著的位置
		legend(condition{1},condition{2},condition{3},'p<.05');
		
		%一段时间的平均电压值的统计
		time1=475;time2=525;%选择某一时间段内的ERP值平均，得到峰值，然后进行统计
		timeidx=find((EEG.times>=time1)&(EEG.times<=time2));%找出感兴趣范围的下标
		sub=[1:30];%确定被试
		chan=15;%确定电极
		xdata=[];
		xdata=mean(data(sub,:,chan,timeidx),[3,4]);%选择data的某些电极和时间段，进行平均后得到每个被试的值
		ljwrmanova(xdata,condition,1)%重复测量方差分析，根据实验设计改用其他

		
		% 地形图
		time1=475;time2=525;%该时间段可以改
		timeidx=find((EEG.times>=time1)&(EEG.times<=time2));%找出感兴趣范围的下标
		figure;
		for j=1:3
			subplot(1,3,j)
			topoplot(squeeze(mean(data(sub,j,:,timeidx),[1,4])),EEG.chanlocs,'emarker2',{chan,'.','r',30,1});%会将设置的chan标红并加大
			caxis([0 10])
			title(condition{j});
		end