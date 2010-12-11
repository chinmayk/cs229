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

numCourses=403;

%Best to worst...recent department grades, overall department grades,
%major, course workload, courses taken
courseacc = zeros(size(courseids,2),5);
numStudents = zeros(size(courseids,2),1);
highprobacc = zeros(size(courseids,2),3);
bestParams = zeros(size(courseids,2),2);

baseline = zeros(size(courseids,2),1);
baseline2 = zeros(size(courseids,2),1); %student's mean grade

opt = 0; %train for acc or train for precision on a's
baserecs = zeros(size(courseids,2),1);

for i=1:size(courseids,2)
    [labels, features] = libsvmread(['concurrcourse',num2str(courseids(i))]);
    
    %get concurrent dept, concurrent courses
    concurrDept = features(:,1:numDepts)./5.0;
    concurrCourses = features(:,(numDepts+1):size(features,2));
    
    [labels, features] = libsvmread(['course',num2str(courseids(i))]);
    
    
    numPrevCourses = features(:, 2*numDepts+2*numCourses+numMajors+3);
    nonzeroRows = find(numPrevCourses>0);
    filteredfeatures = zeros(max(size(nonzeroRows)), size(features,2));
    filteredlabels = zeros(max(size(nonzeroRows)),1);
    newconcurrCourses = zeros(max(size(nonzeroRows)), size(concurrCourses,2));
    
    %filter out students with no courses
    for s=1:max(size(nonzeroRows))
        filteredfeatures(s,:) = features(nonzeroRows(s),:);
        filteredlabels(s) = labels(nonzeroRows(s));
        newconcurrCourses(s,:) = concurrCourses(nonzeroRows(s));
    end
    
    features = filteredfeatures;
    labels = filteredlabels;
    concurrCourses = newconcurrCourses;
    
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
    Cs = [128 64 32 16 8 4 2 1];
    bestC = 1;
    bestCrossAcc = 0;
    
        
    %Baseline is to guess the grade that happens most often
    guess = 1;
    if (sum(labels<0) > sum(labels>0))
        guess = -1;
    end
    baseline_acc = sum(labels==guess)/size(labels,1);
    baseline_prec = sum((labels==guess).*(guess>0))/sum(guess>0);
    baseline_rec = opt_function(guess, labels, 5);

    %Baseline 2 is student's mean grade
    baseline2_guesses = transpose(17*sum(transpose(coursegrades))./sum(transpose(coursegrades>0)));
    %compare against labels
    baseline2_guesses(baseline2_guesses < 14.5) = -1;
    baseline2_guesses(baseline2_guesses >= 14.5) = 1;
    baseline2_guesses(isnan(baseline2_guesses)) = guess;
    
    baseline2_acc = sum(labels==baseline2_guesses)/size(labels,1);
    
    baseline2_prec = sum((labels==baseline2_guesses).*(baseline2_guesses>0))/sum(baseline2_guesses>0);
    baseline2_rec = opt_function(baseline2_guesses, labels, 5);
    baserecs(i) = baseline2_rec;
    
    features = [recentdept concurrCourses coursegrades majorfeatures numHours numPrevCourses];

    gamma = 1.0/size(features,2);
    Gammas = [gamma 2*gamma 4*gamma 8*gamma 16*gamma];
    
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
    


    best_model = 0;
    best_crossacc = 0;
    best_params = [1 1];
    best_testacc = 0;
    
    if (opt == 0)
        for c=1:size(Cs,2)
            for g=1:size(Gammas,2)
                %model = svmtrain(labels_train, training_set, '-t 0');

                %crossacc = svmtrain(labels, features, '-v 10 -t 0');
                %crossacc = svmtrain(labels, features, ['-v 10 -c ', num2str(Cs(c)), ' -g ', num2str(best_params(2))]);
                crossacc = svmtrain(labels_train, training_set, ['-v 10 -c ', num2str(Cs(c)), ' -g ', num2str(Gammas(g))]);
                %svmtrain(labels, features, '-v 10');

                if (crossacc > best_crossacc) %|| (crossacc == best_crossacc && acc_test(1)>best_testacc ))
                    %best_model = model;
                    best_crossacc = crossacc;
                    best_params = [Cs(c) Gammas(g)];
                end
            end
        end
    end
    if (opt == 1)
        for c=1:size(Cs,2)
            for g=1:size(Gammas,2)
                %do 10-fold cross validation
                inds = 1;
                chunk = size(training_set,1)/10.0;
                
                crossacc = 0;
                for x=1:10
                    inds = 1+floor(chunk*(x-1));
                    inde = floor(inds+chunk-1);
                    subset_test = training_set(inds:inde,:);
                    labels_subset_test = labels_train(inds:inde);
                    
                    subset = [training_set(1:inds-1,:);training_set(inde+1:size(training_set,1),:)];
                    labels_subset = [labels_train(1:inds-1);labels_train(inde+1:size(training_set,1))];
                    
                    model = svmtrain(labels_subset, subset, ['-c ', num2str(Cs(c)), ' -g ', num2str(Gammas(g))]);
                    [lte, acc_test] = svmpredict(labels_subset_test, subset_test, model);
                    
                    prec = (1-opt_function(lte, labels_subset_test, opt));
                    if (isnan(prec))
                        prec = 1;
                    end
                    crossacc = crossacc + prec;
                end
                crossacc = crossacc/10.0;
                    
                if (crossacc > best_crossacc)
                   best_crossacc = crossacc;
                   best_params = [Cs(c) Gammas(g)];
                end
            end
        end
    end
    
    chunk = floor(size(training_set,1)/10.0);
    crossprec = 0;
    crossrec = 0;
   for x=1:10
          inds = 1+floor(chunk*(x-1));
          inde = min([floor(inds+chunk-1),size(training_set,1)]);
          subset_test = training_set(inds:inde,:);
          labels_subset_test = labels_train(inds:inde);
                    
          subset = [training_set(1:inds-1,:);training_set(inde+1:size(training_set,1),:)];
          labels_subset = [labels_train(1:inds-1);labels_train(inde+1:size(training_set,1))];
                    
          model = svmtrain(labels_subset, subset, ['-c ', num2str(best_params(1)), ' -g ', num2str(best_params(2))]);
          [lte, acc_test] = svmpredict(labels_subset_test, subset_test, model);
                    
          prec = (1-opt_function(lte, labels_subset_test, 1));
          rec = opt_function(lte, labels_subset_test, 5);
          if (isnan(prec))
            prec = 1;
          end
            crossprec = crossprec + prec;
          if (isnan(rec))
              rec = 1;
          end
              crossrec = crossrec + rec;
    end
    crossprec = crossprec/10.0;
    crossrec = crossrec/10.0;

    model = svmtrain(labels_train, training_set, [' -c ', num2str(best_params(1)), ' -g ', num2str(best_params(2))]);

    [ltr, acc_train] = svmpredict(labels_train, training_set, model);
    
    [lte, acc_test] = svmpredict(labels_test, test_set, model);
    %a_acc = sum((lte==labels_test).*(labels_test>0))/sum(labels_test>0);
    %b_acc = sum((lte==labels_test).*(labels_test<0))/sum(labels_test<0);
    
    %a_acc_train = sum((ltr==labels_train).*(labels_train>0))/sum(labels_train>0);
    %b_acc_train = sum((ltr==labels_train).*(labels_train<0))/sum(labels_train<0);
    
    a_acc = sum((lte==labels_test).*(lte>0))/sum(lte>0);
    b_acc = sum((lte==labels_test).*(lte<0))/sum(lte<0);
    
    a_rec = sum((lte==labels_test).*(labels_test>0))/sum(labels_test>0);
    b_rec = sum((lte==labels_test).*(labels_test<0))/sum(labels_test<0);
    
    
    a_acc_train = sum((ltr==labels_train).*(ltr>0))/sum(ltr>0);
    b_acc_train = sum((ltr==labels_train).*(ltr<0))/sum(ltr<0);
    
    
    crossacc = best_crossacc;
    
    thresh = 0.6;
    
    %acc_high = sum((lte==labels_test).*or(probte(:,1)>thresh, probte(:,2)>thresh))/sum(or(probte(:,1)>thresh, probte(:,2)>thresh));
    %a_acc_high = sum((lte==labels_test).*(labels_test>0).*or(probte(:,1)>thresh, probte(:,2)>thresh))/sum((labels_test>0).*or(probte(:,1)>thresh, probte(:,2)>thresh));
    %b_acc_high = sum((lte==labels_test).*(labels_test<0).*or(probte(:,1)>thresh, probte(:,2)>thresh))/sum((labels_test<0).*or(probte(:,1)>thresh, probte(:,2)>thresh));
    
    courseacc(i,:) = [crossacc, acc_train(1), crossprec, baseline2_prec, crossrec];
  
    %highprobacc(i,:) = [acc_high, a_acc_high, b_acc_high];
    numStudents(i) = size(features,1);
    
    courseacc(isnan(courseacc))=-1;
    %highprobacc(isnan(highprobacc))=-1;
    bestParams(i,:) = best_params;
    baseline(i) = baseline_acc;
    baseline2(i) = baseline2_acc;
    
    %plot_error
end

courseacc
numStudents
bestParams
compareaccs = [courseacc(:,1) baseline baseline2 courseacc(:,3) courseacc(:,4) courseacc(:,5)]
%highprobacc
dlmwrite('svm_comp_filtered.csv', compareaccs);

       