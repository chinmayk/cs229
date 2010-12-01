addpath('C:/Users/sharon/Desktop/liblinear-1.7/matlab');
addpath('C:/Users/sharon/Desktop/liblinear-1.7/windows');

username = 'root';
pass = 'pass';
databasepath = 'jdbc:mysql://localhost:3306/stanford';
conn = database('stanford', username, pass,'com.mysql.jdbc.Driver',databasepath);

%gradeId to number mapping, A(1-3):5, B(4-6):4, C(7-9):3, D(10-12):2,
%F(13):1, Other(14-17):0
%TODO: maybe make a Credit=C and NoCredit=F??
gradeMap = [5,5,5,4,4,4,3,3,3,2,2,2,1,0,0,0,0];
%gradeMap2 = [5,5,5,4,4,4,3,3,3,2,2,2,1,0,0,0,0];
gradeMap2 = [1,1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1];

%record threshold
thresh = 50;

%study programs
curs = exec(conn, 'SELECT studyprogramid FROM `studyprogramst`');
result = fetch(curs);
majorids = cell2mat(result.Data);
numMajors = size(majorids, 1);

%get the course names/ids
curs = exec(conn, ['SELECT courseid FROM `studenthistoryt` WHERE grade<14 group by courseid having count(*)>=',num2str(thresh)]);
result = fetch(curs);
courseids = cell2mat(result.Data);
numCourses = size(courseids,1);

errors = zeros(numCourses,2); %[training error, testing error]

%for each courseid, find the students who have taken the course
for i=1:1%numCourses
    courseid = courseids(i);
    %find students who have taken the course and their grades
    curs = exec(conn, ['SELECT studentid, grade, termid FROM `studenthistoryt` WHERE courseid=',num2str(courseid),' and grade<14']);
    result = fetch(curs);
    students = cell2mat(result.Data(:,1));
    grades = cell2mat(result.Data(:,2)); 
    terms = cell2mat(result.Data(:,3));
    
    %for each student, calculate their feature vectors
    numStudents = size(students,1);
    
    %features = zeros(numStudents, numCourses+numMajors+1);
    features = zeros(numStudents, numMajors+1);
    labels = zeros(numStudents,1);
    nonzeroGrades = 0;
    
    for j=1:numStudents
        %find the courses the student has previously taken
        student = students(j);
        term = terms(j);
        
        studenthistory = zeros(1,numCourses);
        
        %get start date
        curs = exec(conn, ['select startdate from termst where termid=',num2str(term)]);
        startDate = fetch(curs);
        
        %if no start date, ignore
        if (strcmp(cell2mat(startDate.Data),'No Data'))
                continue;
        end
        startDate = datenum(startDate.Data);

        %get student's major (TODO: Get department instead?)
        curs = exec(conn, ['select studyprogramid from studentstudiest where studentid=',num2str(student)]);
        result = fetch(curs);
        majors = cell2mat(result.Data);
        majorfeatures = zeros(1,numMajors);
        for k=1:size(majors,1)
            index = find(majorids == majors(k));
            majorfeatures(index) = 1;
        end
        
        %get student's current quarter workload 
        curs = exec(conn, ['SELECT SUM(units) FROM `studenthistoryt` WHERE studentid=',num2str(student),' and termid=',num2str(term)]);
        result = fetch(curs);
        totalUnits = cell2mat(result.Data);
        
        curs = exec(conn, ['SELECT courseid, grade, termid FROM `studenthistoryt` WHERE studentid=',num2str(student),' and grade<14 and termid!=',num2str(term)]);
        
        result = fetch(curs);
        if (size(result.Data,2) < 3)
            %student has not taken any courses, continue
            %features(j,:) = [studenthistory majorfeatures totalUnits];
            features(j,:) = [majorfeatures totalUnits];
            labels(j) = gradeMap2(grades(j));
            continue;
        end
        prevCourses = cell2mat(result.Data(:,1));
        prevGrades = cell2mat(result.Data(:,2));
        prevTerms = cell2mat(result.Data(:,3));
        
        %calculate the feature vector
        %[prev course grades | student's major | current
        %quarter workload in credits]
        %Currently overwriting grades if course taken more than once...
        for k=1:size(prevCourses,1)
            %ignore courses taken later or at the same time
            curs = exec(conn, ['select startdate from termst where termid=',num2str(prevTerms(k))]);
            prevDate = fetch(curs);
            if (strcmp(cell2mat(prevDate.Data),'No Data'))
                continue;
            end
            prevDate = datenum(prevDate.Data);
            if (prevDate >= startDate)
                continue;
            end
            index = find(courseids == prevCourses(k));
            if (size(index,2)>0)
                studenthistory(index) = gradeMap(prevGrades(k));
            end
        end
        
        %find number of nonzero recorded grades (debugging purposes)
        nonzeroGrades = nonzeroGrades + size(find(studenthistory>0),2);
        %features(j,:) = [studenthistory majorfeatures totalUnits];
        features(j,:) = [majorfeatures totalUnits];
        labels(j) = gradeMap2(grades(j));
        
    end  
    nonzeroGrades = nonzeroGrades/numStudents;
    
    testerror = 0;
    trainerror = 0;
    %leave one out cross-validation
    for n=1:numStudents
       %leave out student l, train on the rest
       subset = features(1:n-1,:);
       featurestrain = [subset; features(n+1:numStudents,:)];
       
       subsetl = labels(1:n-1);
       labelstrain = [subsetl; labels(n+1:numStudents)];
       
       model = train(labelstrain, sparse(featurestrain));
       
       %training error
       [ltrain, acctrain] = predict(labelstrain, sparse(featurestrain), model);
       trainerror = trainerror + (100-acctrain);
       
       %test error
       [ltest, acctest] = predict(labels(n,:), sparse(features(n,:)), model);
       
       testerror = testerror + (100-acctest);
    end
    
    crossacc = train(labels, sparse(features), '-v 10');
   
    trainerror = trainerror/numStudents;
    testerror = testerror/numStudents;
    errors(i,:) = [trainerror testerror];
    %model = train(labels, sparse(features));
    %[l,a] = predict(labels, sparse(features), model);
end
