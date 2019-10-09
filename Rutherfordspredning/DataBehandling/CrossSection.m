clear all; close all;clc;
    

c2E = @(x) x*0.76535+15.78
theta =       [30,            40,           50,             60,            70,            75,            110,           120,           130,           140,           150,           160]
peakValues =  {c2E([434,445]),c2E([434,431]),c2E([433,427]),c2E([433,410]),c2E([433,396]),c2E([428,388]),c2E([432,350]),c2E([433,340]),c2E([433,330]),c2E([433,323]),c2E([433,318]),c2E([433,314])};
peakBorders = {[390,480],     [380,490],     [380,480],     [350,460],     [340,460],     [340,455],     [310,455],     [300,455],     [280,455],     [280,455],     [280,455],     [280,455]};

linFun =@(beta,x) (x-beta(2))/beta(1);
data = [];


for i = 1:length(theta)
    [X,Y,Yerr] =hisFraData(['..\Data\AngularDependency\' num2str(theta(i)) 'degree.asc']);
    data = [data, fitGaussInSpectrum(X,Y,Yerr,[num2str(theta(i)) ' degree'],peakValues{i},peakBorders{i})];
end



function [X,Y,Yerr] = hisFraData(filename)
% addpath('..\data\Kalibrering')
% delimiter = ' ';
% startRow = 6;
% formatSpec = '%f%f%f%[^\n\r]';
% fileID = fopen(filename,'r');
% dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
% fclose(fileID);
% timestamp = dataArray{:, 1};
% channel = dataArray{:, 2};
% VarName5 = dataArray{:, 3};
% clearvars filename delimiter startRow formatSpec fileID dataArray ans;
% 
% X = 1:max(channel);
% for i = X
%     Y(i) = sum(channel==i);
% end
% Yerr = sqrt(Y) +(Y==0);
filename;
spectrum = importfile(filename);
X = 1:length(spectrum);
Y = spectrum;
Yerr = sqrt(Y);
end

%%
% data har sturktur [peakChannel,peakUns,peakValue]

function data = fitGaussInSpectrum(X,Y,Yerr,name,peakValue,peakBorder)
n = length(peakValue);

% 
% figure
% errorbar(X*0.76535+15.78,Y,Yerr,'.')
% % errorbar(X,Y,Yerr,'.','markersize',10)
% 
% xlabel('Energy (E) [MeV]')
% % xlabel('Channel number')
% ylabel('Counts (n)')
% set(gca,'FontSize',15) 
% 
% hold on
% for i = 1:n
%     plot([peakValue(i),peakValue(i)],[0,500])
% end


figure
errorbar(X,Y,Yerr,'.','markersize',10)
hold on
xlabel('Channel number (Ch)')
ylabel('Counts (n)')
set(gca,'FontSize',15) 
title(name)

x2 =   peakBorder(1);
x3 =   peakBorder(2);  
xlim([x2,x3])


x = X;
y = Y;
yerr = Yerr;
higherIndex = x>x2;
x = x(higherIndex);
y = y(higherIndex);
yerr = yerr(higherIndex);

lowerIndex = x<x3;
x = x(lowerIndex);
y = y(lowerIndex);
yerr = yerr(lowerIndex);

peakChannel = (peakValue-15.78)./0.76535 


beta0 = [0,0,y(round(peakChannel(1))==x),peakChannel(1),10,y(round(peakChannel(2))==x),peakChannel(2),20,0];

for i = 1:n
    plot([peakChannel(i),peakChannel(i)],[0,max(y)])
end

% plot(x,fitfunction(beta0,x))
hold on 
w = 1./yerr.^2;
w = ones(size(yerr))
[beta,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(x,y,@fitfunction,beta0,'weights',w);
beta(1);
beta(2);
plot(x,fitfunction(beta,x),'linewidth',2)
plot(x,beta(1).*x+beta(2)+beta(9).*x.^2+beta(3).*exp(-((x-beta(4))./(beta(5))).^2./2),'--')
plot(x,beta(1).*x+beta(2)+beta(9).*x.^2+beta(6).*exp(-((x-beta(7))./(beta(8))).^2./2),'--')
plot(x,beta(1).*x+beta(2)+beta(9).*x.^2,'--')

% plot(x,beta(4).*x+beta(5))
us = CovB/MSE;
mse =MSE;
MSECount(i) = MSE;
pValue(i) = 1-chi2cdf(MSE*(length(y)-5),(length(y)-5));
P_Value = 1-chi2cdf(MSE*(length(y)-5),(length(y)-5));


txt = text(beta(4),y(round(beta(4))==x)+10,['\leftarrow' num2str(beta(4)) '']);
set(txt,'Rotation',90);
set(txt,'FontSize',12);

txt = text(beta(7),y(round(beta(7))==x)+10,['\leftarrow' num2str(beta(7)) '']);
set(txt,'Rotation',90);
set(txt,'FontSize',12);

% plot([beta(1)+us(1,1),beta(1)+us(1,1)],[0,max(y)])
% plot([beta(1)-us(1,1),beta(1)-us(1,1)],[0,max(y)])

peakChannel(i) = beta(1,1);
peakUns(i) = us(1,1);
ci = nlparci(beta,R,'jacobian',J,'alpha',0.35)
peakUns(i) = (ci(1,2)-ci(1,1))/2;
% peakUns(i) = us(1,1);


data = [peakChannel;peakUns;peakValue;pValue;MSECount];
end


function y = fitfunction(beta,x)
    y = beta(1).*x+beta(2)+beta(3).*exp(-((x-beta(4))./(beta(5))).^2./2)+beta(6).*exp(-((x-beta(7))./(beta(8))).^2./2)-abs(beta(9)).*x.^2;
    y =y';
end