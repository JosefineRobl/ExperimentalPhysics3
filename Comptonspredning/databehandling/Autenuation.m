clear all; close all;clc;
folderName = {'Aluminum','Lead','Cupper','Brass'}
name = {'Al','Pb','Cu','Brass'}

channelInterval= [[480,600],[450,620],[450,620],[450,620]];
deltaThiknessLead = [1.13,1.10,1.13,1.01,1.04,1.05,1.05,1.19,1.06,1.21];
plateThiknessLead(1) = 0;
for i=1:length(deltaThiknessLead)
    plateThiknessLead(i+1) = sum(deltaThiknessLead(end-i+1:end));
end
plateThikness = {[0,10.11,20.22,30.34,40.46,50.55,60.65,70.79,80.9],[plateThiknessLead],[0,1.02,2.06,3.05,4.04,5.06,6.10,7.09,8.12,9.11],[0,7.98,16.03,24.02]};
plateThiknessUncertanty = 0.02;

for i = 1:length(name)
    counts=zeros(size(plateThikness{i}));
    pathStart = ['..\data\AttenuationCoefficient\' folderName{i} '\AttenuationCoefficient_' name{i} '_'];
        for j = 1:length(plateThikness{i})
            path  = [pathStart num2str(j-1) 'Plates_ch001.txt'];
            [X,Y,Yerr] = hisFraData(path);
            counts(j) = sum(Y((channelInterval(1,1):channelInterval(1,2))));
%             figure
%             title([name{i},': measurement num: ',num2str(j),', T =',num2str(plateThikness{i}(j))])
%             hold on
%             plot(X,Y,'.')
%             xlabel('Channel')
%             ylabel('Counts')
%             plot(X([channelInterval(1,1):channelInterval(1,2)]),Y([channelInterval(1,1):channelInterval(1,2)]),'*')
        end 
    figure
    hold on
    xlabel('Thikness of material [cm^-1]')
    ylabel('Counts under peak')

    cErr = sqrt(counts);
    x = plateThikness{i}
    y = counts
    yerr = cErr;
    beta0 = [y(1)-y(end),-0.1,y(end)];
    linFun =@(beta,x) beta(1).*exp(x./beta(2))+beta(3);
    plot(x,linFun(beta0,x))
    w = 1./yerr.^2;
    [beta,R,J,CovB,MSE,ErrorModelInfo]  = nlinfit(x,y,@(beta,x) linFun(beta,x),beta0,'weights',w);
    yerr = sqrt(yerr.^2 + (beta(1).*beta(2).*exp(beta(2).*x)*plateThiknessUncertanty).^2);
    w = 1./yerr.^2;
    errorbar(x,y,yerr,'.')
%     [beta,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(x,y,@(beta,x) linFun(beta,x),beta,'weights',w);
    
    hold on
    xs = linspace(x(1),x(end)+2,1000);
    plot(xs,linFun(beta,xs))
    us = CovB/MSE;
    US{i} = us;
    mse{i} = MSE;
    BETA{i} = beta
    pValue= 1-chi2cdf(MSE*(length(y)-2),(length(y)-2));
    PvALUE{i} = pValue;
    title(['Fit of autenuation for material ',name{i},', P-value =',num2str(pValue)])
    
    disp(['Fit of atenuation for ',name{i}, ' gives tau = ', num2str(beta(2)),'\pm',num2str(us(2,2)),' cm^-1'])
    disp(['and bacground = ', num2str(beta(3)),'+-',num2str(us(3,3)),' counts.'])
    disp(['With MSE = ', num2str(MSE),' with p-value: ',num2str(pValue)])

end



function [X,Y,Yerr] = hisFraData(filename)
delimiter = ' ';
startRow = 6;
formatSpec = '%f%f%f%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
fclose(fileID);
timestamp = dataArray{:, 1};
channel = dataArray{:, 2};
VarName5 = dataArray{:, 3};
clearvars filename delimiter startRow formatSpec fileID dataArray ans;
X = 1:max(channel);
for i = X
    Y(i) = sum(channel==i);
end
Yerr = sqrt(Y) +(Y==0);
end
