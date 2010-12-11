addpath('C:/Users/sharon/Desktop/libsvm-mat-3.0-1/libsvm-mat-3.0-1');
addpath('C:/Users/sharon/My Documents/MATLAB/old');

%username = 'root';
%pass = '';
%databasepath = 'jdbc:mysql://localhost:3306/stanford';
%conn = database('stanford', username, pass,'com.mysql.jdbc.Driver',databasepath);

courseids = [1738, 3634, 6107, 10853, 12688, 17316, 20197, 21837, 23805, 31075, 31632, 1962, 6107, 16796, 21691, 23092, 23849, 29783];
%courseids = [1738, 3634, 6107, 10853];
%courseids = [1962 6107 16796 21691 23092 23849 29783];

%study programs
%curs = exec(conn, 'SELECT studyprogramid FROM `studyprogramst`');
%result = fetch(curs);
%majorids = cell2mat(result.Data);
numMajors = 76;%size(majorids, 1);

%get the department ids
%curs = exec(conn, 'SELECT distinct departmentid FROM `unifiedhistorygrades` WHERE grade<14');
%result = fetch(curs);
%deptids = cell2mat(result.Data);
numDepts = 177;%size(deptids,1);

gradeMap = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17];
%gradeMap = [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,1,1,1,1,1];

numCourses=403;

%Best to worst...recent department grades, overall department grades,
%major, course workload, courses taken
courseacc = zeros(size(courseids,2),5);
numStudents = zeros(size(courseids,2),1);
highprobacc = zeros(size(courseids,2),3);
%bestParams = zeros(size(courseids,2),2);

baseline = zeros(size(courseids,2),1);
baseline2 = zeros(size(courseids,2),1); %student's mean grade

opt = 0; %train for acc or train for precision on a's

numSVs = zeros(size(courseids,2),17);

compareaccs = zeros(size(courseids,2),14);
within12 = zeros(size(courseids,2),2);
withino12 = zeros(size(courseids,2),2);
for i=1:size(courseids,2)
    [origlabels, features] = libsvmread(['concurrcourse',num2str(courseids(i))]);
    
    %get concurrent dept, concurrent courses
    concurrDept = features(:,1:numDepts)./5.0;
    concurrCourses = features(:,(numDepts+1):size(features,2));
    
    [origlabels, features] = libsvmread(['newcourse',num2str(courseids(i))]);
    labels = origlabels;
    for l=1:size(origlabels,1)
        labels(l) = gradeMap(origlabels(l));
    end
    
    uniqLabels = unique(labels);
    %uniqLabels = uniqLabels(2:size(uniqLabels,1)); %exclude first label
    
    bestParams = zeros(size(uniqLabels,1),2); %bestParams per label
    
    %train an SVM for each unique label

    
    %scale the data
    cursor = 1;
    recentdept = features(:,1:numDepts)./4.33;
    cursor = numDepts+1;
    deptgrades = features(:,cursor:(cursor+numDepts-1))./4.33;
    cursor = cursor+numDepts;
    coursegrades = features(:,cursor:(cursor+numCourses-1))./17.0;
    cursor = cursor+numCourses;
    ratings = features(:,cursor:(cursor+numCourses-1))./5.0;
    cursor= cursor+numCourses;
    majorfeatures = features(:,cursor:(cursor+numMajors-1));
    cursor = cursor+numMajors;
    numCredits = features(:,cursor)./25.0;
    cursor = cursor+1;
    numHours = features(:,cursor)./25.0;
    cursor = cursor+1;
    numPrevCourses = features(:, cursor)./80.0;
    

    %C's to try
    %Cs = [128 64 32 16 8]; %4 2 1];
    Cs = [64 32 16 8];
    bestC = 1;
    bestCrossAcc = 0;
    
    
        %Baseline is to guess the mean course grade
    meanguess = repmat(round(mean(labels)), size(labels));
    baseline_acc = opt_function(meanguess, labels, 2);
    baseline_l2 = opt_function(meanguess, labels, 4);
    baseline_rms = opt_function(meanguess, labels, 3);
    
    withino1 = size(find(abs(meanguess-labels)<=1),1)/size(labels,1);
    withino2 = size(find(abs(meanguess-labels)<=2),1)/size(labels,1);
    
    withino12(i,:) = [withino1 withino2];

    %Baseline 2 is student's mean grade
    baseline2_guesses = transpose(17*sum(transpose(coursegrades))./sum(transpose(coursegrades>0)));
    
    sum(numPrevCourses==0)/size(features,1)
    
    baseline2_guesses(isnan(baseline2_guesses)) = round(meanguess(1));
    
    %compare against labels
    %baseline2_guesses(baseline2_guesses < 14.5) = -1;
    %baseline2_guesses(baseline2_guesses >= 14.5) = 1;
    
    baseline2_acc = opt_function(baseline2_guesses, labels, 2);
    baseline2_l2 = opt_function(baseline2_guesses, labels, 4);
    baseline2_rms = opt_function(baseline2_guesses, labels, 3);
    
    withinb1 = size(find(abs(baseline2_guesses-labels)<=1),1)/size(labels,1);
    withinb2 = size(find(abs(baseline2_guesses-labels)<=2),1)/size(labels,1);
    
    
    continue;
    features = [recentdept concurrCourses coursegrades majorfeatures numHours numPrevCourses baseline2_guesses];
    %features = zeros(size(numPrevCourses,1),1)%[numPrevCourses];

    gamma = 1.0/size(features,2);
    Gammas = [gamma 2*gamma 4*gamma] %8*gamma 16*gamma];
    
    train_size = size(features,1);%round(0.9*size(features,1));
    order = randperm(size(features,1));

    randomized_features = features;
    randomized_labels = labels;

    for f=1:size(features,1)
       randomized_features(f,:) = features(order(f),:); 
       randomized_labels(f) = labels(order(f));
    end

    next = train_size+1;
    training_set = randomized_features(1:train_size,:);
    test_set = randomized_features(next:size(features,1),:);
    labels_train = randomized_labels(1:train_size);
    labels_test = randomized_labels(next:size(features,1));
    

    %baseline2_prec = sum((labels==baseline2_guesses).*(baseline2_guesses>0))/sum(baseline2_guesses>0);
    
    best_model = 0;
    best_params = [1 1];
    best_testacc = 0;
    
    labelsByGrade = zeros(size(labels_train,1), size(uniqLabels,1));
    for u=1:size(uniqLabels,1)
        labels_train2 = (labels_train >= uniqLabels(u))+0;
        labels_train2(labels_train2==0) = -1;
        labelsByGrade(:,u) = labels_train2;
    end
    
    %train SVM on this grade or above
    for u=1:size(uniqLabels,1)
        best_crossacc = 0;
        labels_train2 = labelsByGrade(:, u);
        if (opt == 0)
            for c=1:size(Cs,2)
                for g=1:size(Gammas,2)     
                    crossacc = svmtrain(labels_train2, training_set, ['-v 10 -c ', num2str(Cs(c)), ' -g ', num2str(Gammas(g))]);
                    if (crossacc > best_crossacc)
                        best_crossacc = crossacc;
                        best_params = [Cs(c) Gammas(g)];
                        bestParams(u,:) = [Cs(c) Gammas(g)];
                    end
                end
            end
        end
    end
    
    chunk = ceil(size(training_set,1)/10.0);
    crossprec = 0;
    crossl2 = 0;
    crossrms = 0;
    
    %within 1 point
    within1 = 0;
    %within 2 points
    within2 = 0;
    crossacc = 0;
    
    totalSize = 0;
    nfolds = 10;
   for x=1:nfolds
       
       inds = 1+floor(chunk*(x-1));
       inde = min([floor(inds+chunk-1),size(training_set,1)]);
       gradevote = zeros(inde-inds+1,17);
       
       subset_test = training_set(inds:inde,:);
       labels_subset_test = labels_train(inds:inde);
       for u=1:size(uniqLabels,1)
          labels_train2 = labelsByGrade(:,u);

          labels_subset_test2 = labels_train2(inds:inde);
                    
          subset = [training_set(1:inds-1,:);training_set(inde+1:size(training_set,1),:)];
          labels_subset = [labels_train2(1:inds-1);labels_train2(inde+1:size(training_set,1))];
                    
          model = svmtrain(labels_subset, subset, ['-c ', num2str(bestParams(u,1)), ' -g ', num2str(bestParams(u,2))]);
          [lte, acc_test] = svmpredict(labels_subset_test2, subset_test, model);
          
          %record numSVs
          numSVs(i, uniqLabels(u)) = numSVs(i, uniqLabels(u)) + model.totalSV;
          
          %figure out grade vote
          for lu=1:size(labels_subset_test2)
             if(lte(lu)>0)
                 gradevote(lu,uniqLabels(u):17) = gradevote(lu,uniqLabels(u):17) + 1;
             else
                 gradevote(lu,1:uniqLabels(u)-1) = gradevote(lu,1:uniqLabels(u)-1) + 1;
             end
          end
       end
       %figure out the grade with the max votes
       lte = zeros(size(labels_subset_test,1),1);
       for lu=1:size(lte,1)
           lte(lu) = median(find(gradevote(lu,:)==max(gradevote(lu,:))));
       end
                       
       prec = opt_function(lte, labels_subset_test, 2);
       l2 = opt_function(lte, labels_subset_test, 4);
       rms = opt_function(lte, labels_subset_test, 3);
       cacc = 1-opt_function(lte, labels_subset_test,0);
          
       within1 = within1 + size(find(abs(lte-labels_subset_test)<=1),1);
       within2 = within2 + size(find(abs(lte-labels_subset_test)<=2),1);
       totalSize = totalSize + size(lte,1);
          
       if (isnan(prec))
         prec = 1;
       end
       crossprec = crossprec + prec;
       crossrms = crossrms + rms;
       crossl2 = crossl2 + l2;
       crossacc = crossacc + cacc;
    end
    crossprec = crossprec/nfolds;
    crossrms = crossrms/nfolds;
    crossl2 = crossl2/nfolds;
    crossacc = crossacc/nfolds;
    
           
    numSVs(i, :) = numSVs(i,:)./nfolds;
    
    within1 = within1/size(training_set,1);
    within2 = within2/size(training_set,1);
    
    within12(i,:) = [within1 within2];
    
    compareaccs(i,:) = [crossacc, crossprec, crossl2, crossrms, baseline_acc, baseline_l2, baseline_rms, baseline2_acc, baseline2_l2, baseline2_rms, within1, within2, withinb1, withinb2];

    numStudents(i) = size(features,1);
    
    courseacc(isnan(courseacc))=-1;

    baseline(i) = baseline_acc;
    baseline2(i) = baseline2_acc;
    
    %plot_error
    %dlmwrite(['predicted-,'.csv'], compareaccs);
end

courseacc
numStudents
%bestParams
compareaccs
%compareaccs = [courseacc(:,1) baseline baseline2 courseacc(:,3)]
%highprobacc
%dlmwrite('multisvm_comp_wbaselines.csv', compareaccs);

       