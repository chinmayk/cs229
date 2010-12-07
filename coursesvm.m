%addpath('C:/Users/sharon/Desktop/liblinear-1.7/matlab');
%addpath('C:/Users/sharon/Desktop/liblinear-1.7/windows');
addpath('C:/Users/sharon/Desktop/libsvm-mat-3.0-1/libsvm-mat-3.0-1');

username = 'root';
pass = '';
databasepath = 'jdbc:mysql://localhost:3306/stanford';
conn = database('stanford', username, pass,'com.mysql.jdbc.Driver',databasepath);

includeRatings = 1;
includeTranscript = 1;
includeMajor = 1;
includeUnits = 1;
includeWorkload = 1;
includeHours = 1;
includeNumCoursesTaken = 1;
includeDeptGrades = 1;

%gradeId to number mapping, A(1-3):5, B(4-6):4, C(7-9):3, D(10-12):2,
%F(13):1, Other(14-17):0
%TODO: maybe make a Credit=C and NoCredit=F??
%gradeMap = [5,5,5,4,4,4,3,3,3,2,2,2,1,0,0,0,0];
%gradeMap = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
%labelMap = [5,5,5,4,4,4,3,3,3,2,2,2,1,0,0,0,0];
gradeMap = 17:-1:1;
gradeMap(14:17) = 0;
%labelMap = 17:-1:1;
labelMap = [1,1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1];
%labelMap = [-1,-1,-1,1,1];
%gradeMap = [1,2,3,4,5];

%record threshold
thresh = 50;

%study programs
curs = exec(conn, 'SELECT studyprogramid FROM `studyprogramst`');
result = fetch(curs);
majorids = cell2mat(result.Data);
numMajors = size(majorids, 1);

%get the department ids
curs = exec(conn, 'SELECT distinct departmentid FROM `unifiedhistorygrades` WHERE grade<14');
result = fetch(curs);
deptids = cell2mat(result.Data);
numDepts = size(deptids,1);

%get the course names/ids
curs = exec(conn, ['SELECT courseid FROM `studenthistoryt` WHERE grade<14 group by courseid having count(*)>=',num2str(thresh),' ORDER BY count(*) desc']);
%curs = exec(conn, ['SELECT courseid FROM `studenthistoryt` WHERE 1 group by courseid having count(*)>=',num2str(thresh)]);
result = fetch(curs);
courseids = cell2mat(result.Data);
numCourses = size(courseids,1);

errors = zeros(numCourses,2); %[training error, testing error]

courseacc = zeros(numCourses, 5);

filter = [6441,7843,23092,28713,8739,11411,15497,5600,4268,29783,30703,19328,15262,25919,21740];
%for each courseid, find the students who have taken the course
for i=25:40
    courseid = courseids(i);
    
    %if (courseid ~= 10853 && courseid ~= 3634)
    %if (min(size(find(filter==courseid)))==0)
    %    continue;
    %end
    %find students who have taken the course and their grades
    %curs = exec(conn, ['SELECT studentid, grade, termid FROM `studenthistoryt` WHERE courseid=',num2str(courseid),' and grade<14 ORDER BY grade']);
    curs = exec(conn, ['SELECT studentid, grade, termid FROM `studenthistoryt` WHERE courseid=',num2str(courseid),' and grade!= 17 and grade !=14 ORDER BY grade']);
  
    result = fetch(curs);
    students = cell2mat(result.Data(:,1));
    grades = cell2mat(result.Data(:,2)); 
    terms = cell2mat(result.Data(:,3));
    
    %for each student, calculate their feature vectors
    numStudents = size(students,1);
    
    features = zeros(numStudents, 2*numCourses+numMajors+3+2*numDepts);
    %features = zeros(numStudents, numMajors+3);
    labels = zeros(numStudents,1);
    
    for j=1:numStudents
        %find the courses the student has previously taken
        student = students(j);
        term = terms(j);
        
        studenthistory = zeros(1,numCourses);
        ratingshistory = zeros(1,numCourses);
        deptgradeshistory = zeros(1,numDepts);
        deptgradesrecent = zeros(1,numDepts);
        
        %get start date
        curs = exec(conn, ['select startdate from termst where termid=',num2str(term)]);
        startDate = fetch(curs);
        
        %if no start date, ignore
        if (strcmp(cell2mat(startDate.Data),'No Data'))
                continue;
        end
        startDate = datenum(startDate.Data);
        
        %get student's dept gpa
        curs = exec(conn, ['select sum(points)/count(*), departmentid from unifiedhistorygrades where grade<14 and studentid=',num2str(student),' and startdate<"', datestr(startDate,'yyyy-mm-dd'),'" group by departmentid']);
        result = fetch(curs);
        if (size(result.Data,2) == 2)
            currGPA = cell2mat(result.Data(:,1));
            currDept = cell2mat(result.Data(:,2));
            
            for d=1:size(currDept,1)
                %find dept index
                index = find(deptids==currDept(d));
                deptgradeshistory(index) = currGPA(d);
            end
        end
        
        %get student's recent dept gpa, within 300 days
        curs = exec(conn, ['select sum(points)/count(*), departmentid from unifiedhistorygrades where grade<14 and studentid=',num2str(student),' and startdate<"', datestr(startDate,'yyyy-mm-dd'),'" and startdate>="', datestr(startDate-300,'yyyy-mm-dd'),'" group by departmentid']);
        result = fetch(curs);
        if (size(result.Data,2) == 2)
            currGPA = cell2mat(result.Data(:,1));
            currDept = cell2mat(result.Data(:,2));
            
            for d=1:size(currDept,1)
                %find dept index
                index = find(deptids==currDept(d));
                deptgradesrecent(index) = currGPA(d);
            end
        end
        
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
        curs = exec(conn, ['SELECT SUM(units), COUNT(*) FROM `studenthistoryt` WHERE studentid=',num2str(student),' and termid=',num2str(term)]);
        result = fetch(curs);
        totalUnits = max([cell2mat(result.Data(1)), cell2mat(result.Data(2))]); 
        
        curs = exec(conn, ['SELECT courseid, units FROM `studenthistoryt` WHERE studentid=',num2str(student),' and termid=',num2str(term)]);
        result = fetch(curs);
        currCourses = cell2mat(result.Data(:,1));
        currUnits = cell2mat(result.Data(:,2));
        
        totalHours = 0;

        for k=1:size(currCourses,1)
            curs = exec(conn, ['SELECT SUM((workload_id*num_responses))/SUM(num_responses), term_id  FROM `workload_courses` where course_id=',num2str(courseid),' GROUP BY term_id']);
            result = fetch(curs);
            
             if (size(result.Data,2) < 2)
                 totalHours = totalHours + currUnits(k);
                 continue;
             end
            
            workloads = cell2mat(result.Data(:,1));
            workloadTerms = cell2mat(result.Data(:,2));
        
            sumWorkloads = 0;
            totalValidWorkloads = 0;
            for n=1:size(workloadTerms,1)
                curs = exec(conn, ['select startdate from termst where termid=',num2str(workloadTerms(n))]);
                prevDate = fetch(curs);
                if (strcmp(cell2mat(prevDate.Data),'No Data'))
                    continue;
                end
                prevDate = datenum(prevDate.Data);
               % if (prevDate > startDate)
               %     continue;
               % end
                sumWorkloads = sumWorkloads + workloads(n);
                totalValidWorkloads = totalValidWorkloads+1;
            end
            if (totalValidWorkloads > 0)
                totalHours = totalHours + (sumWorkloads/totalValidWorkloads);
            else
                totalHours = totalHours + max([currUnits(k),1]);
            end
        end
        
        coursesTaken = 0;
        curs = exec(conn, ['SELECT courseid, grade, termid, rating FROM `unifiedhistorygrades` WHERE studentid=',num2str(student),' and startDate<"', datestr(startDate,'yyyy-mm-dd'),'"']);
        %curs = exec(conn, ['SELECT courseid, grade, termid FROM `studenthistoryt` WHERE studentid=',num2str(student),' and grade<14 and termid=',num2str(term)]);
        
        %curs = exec(conn, ['SELECT courseid, rating, termid FROM `studenthistoryt` WHERE studentid=',num2str(student),' and rating>0 and termid!=',num2str(term)]);
        result = fetch(curs);
        if (size(result.Data,2) < 4)
            %student has not taken any courses, continue
            features(j,:) = [deptgradesrecent deptgradeshistory studenthistory ratingshistory majorfeatures totalUnits totalHours coursesTaken];
            %features(j,:) = [majorfeatures totalUnits totalHours coursesTaken];
            labels(j) = labelMap(grades(j));
            continue;
        end
        prevCourses = cell2mat(result.Data(:,1));
        prevGrades = cell2mat(result.Data(:,2));
        prevTerms = cell2mat(result.Data(:,3));
        prevRatings = cell2mat(result.Data(:,4));
        
        %calculate the feature vector
        %[prev course grades | student's major | current
        %quarter workload in credits]
        %Currently overwriting grades if course taken more than once...

        for k=1:size(prevCourses,1)
            %ignore courses taken later or at the same time
            index = find(courseids == prevCourses(k));
            if (size(index,2)>0)
                studenthistory(index) = gradeMap(prevGrades(k));
                ratingshistory(index) = prevRatings(k);
            end
            coursesTaken = coursesTaken + 1;
        end
        
        %find number of nonzero recorded grades (debugging purposes)
        features(j,:) = [deptgradesrecent deptgradeshistory studenthistory ratingshistory majorfeatures totalUnits totalHours coursesTaken];
        %features(j,:) = [majorfeatures totalUnits totalHours coursesTaken];
        labels(j) = labelMap(grades(j));
        
    end  
    
    testerror = 0;
    trainerror = 0;
    labelstest = zeros(numStudents,1);
    
    %order = randperm(numStudents);
    
    libsvmwrite(['course',num2str(courseids(i))], labels, sparse(features));
    numStudents
    
    %crossacc = train(labels, sparse(features), '-v 10');
    %crossacc = svmtrain(labels, sparse(features), '-v 10  -w5 0.3');
    %crossacc = svmtrain(labels, features, '-v 10 -t 0');
    %model = svmtrain(labels, features, '-t 0');
    %[ltrain, acctrain] = svmpredict(labels, features, model);
   
    %trainerror = trainerror/numStudents;
    %testerror = testerror/numStudents;
    %errors(i,:) = [trainerror(1) testerror(1)];
    %model = train(labels, sparse(features));
    %[l,a] = predict(labels, sparse(features), model);
    %traintest;
    %courseacc(i,:) = [acc_train(1), crossacc, acc_test(1), a_acc, b_acc];
    clearvars features;
end
