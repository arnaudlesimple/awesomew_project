clear
close all


Action = load('SPD/Event Window.mat');
Action = Action.Event_window;
Event=load('SPD/WindowLabel.mat');%WindowLabel
Event=Event.labelAction;

%%
psd_small_laplacian = load('SPD/SPD with SmallLaplacian Spatial filtre.mat');
psd_large_laplacian = load('SPD/SPD with LargeLaplacian Spatial filtre.mat');
psd_CAR_filter = load('SPD/SPD with CAR Spatial filtre.mat');
psd_no_spatial_filter = load('SPD/SPD with NO Spatial filtre');

selected_data=psd_CAR_filter.psdt;

window_frequency = 16;
frequencies = load('SPD/Frequences.mat');
load('SPD/Frequences.mat');

mu_band = [3:6];
beta_band = [7:18];
mu_beta_band = [3:18];
all_band=1:23;

band = {mu_band, beta_band};
band_selected = all_band;


%%

discrimancy = GetDiscrimancyMap(selected_data, band_selected, window_frequency, frequencies);

%%




start_feedback=Action(:,4);
end_feedback=Action(:,5);

trial_label=Action(:,1);

selected_features= [24 9; 12 2; 12 3; 12 5; 12 7;12 8;12 11]; %[frequ x channel]

selected_features=[selected_features(:,1)./2-1,selected_features(:,2)]; %[frequ_INDEX x channel


%%
window_feat=zeros(length(start_feedback),min(end_feedback-start_feedback),size(selected_features,1)); % trial x window x features
window_label=zeros(length(start_feedback),min(end_feedback-start_feedback),2);

for i=1:length(start_feedback)
    
    Window_single_feat=[];
    
    for a=1:length(selected_features)
    Window_single_feat=[Window_single_feat,selected_data(start_feedback(i):end_feedback(i),selected_features(a,2),selected_features(a,1))];
    end
    
    window_feat(i,:,:)=Window_single_feat(1:min(end_feedback-start_feedback),:);
    
   % temp=ones(end_feedback(i)-start_feedback(i)+1,2).*[Action(i,1),i]
   
    window_label(i,:,:)=ones(min(end_feedback-start_feedback),2).*[Action(i,1),i];
 end

%%

partition = cvpartition(length(start_feedback), 'KFold', 10);



%%
single_sample_accuracy=zeros(10,1);

for i=1:10
    %je veux avoir les windows des trials ensemble dans les sets
    
    train_trials=find(partition.training(i));
    test_trials=find(partition.test(i));
    
    training_set=[];
    testing_set=[];
   
    train_label=[];
    test_label=[];
    
    for n=1:partition.TrainSize(i)
    training_set=[training_set;squeeze(window_feat(train_trials(n),:,:))];
    train_label=[train_label;squeeze(window_label(train_trials(n),:,:))];
    end
    
    for n=1:partition.TestSize(i)
    testing_set=[testing_set;squeeze(window_feat(test_trials(n),:,:))];
    test_label=[test_label;squeeze(window_label(test_trials(n),:,:))];
    end
    
classifier = fitcdiscr(training_set, train_label(:,1), 'discrimtype', 'linear'); %train an LDA classifier

[predicted_label,score,cost] = predict(classifier, testing_set); %score [771 773]

single_sample_accuracy(i) =  accuracy( test_label(:,1), predicted_label);

%trial accuracy
alpha=0.99;
decision=zeros(78,3);
final_classification=zeros(3,1);
    for m=1:partition.TestSize(i)
    
        N=test_trials(m)
        
        ProbaTrial=score(test_label(:,2)==N);
        
        for l=2:length(ProbaTrial)
        
            decision(l,m)=score(l,1)*alpha+decision(l-1,m)*(1-alpha);
            
            if decision(l,m) > 0.885
               
                final_classification(m)=771;
%             else if decision(l,m) < 0.2
%                   final_classification(m)=773;  
%                 end
            end
            
        end
    end
         
       
end

avg_s_s_accuracy=mean(single_sample_accuracy);










function [class_accuracy]=accuracy(real_label, predicted_label)
    false=nnz(real_label-predicted_label);
    
    class_accuracy=1-(false/length(real_label));
end
    