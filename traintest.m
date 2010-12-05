train_size = round(0.9*size(features,1));
order = randperm(size(features,1));

labels_train = zeros(train_size,1);
labels_test = zeros(size(features,1)-train_size,1);

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

model = svmtrain(labels_train, training_set, '-t 0');
[ltr, acc_train] = svmpredict(labels_train, training_set, model);

[lte, acc_test] = svmpredict(labels_test, test_set, model);

svmtrain(labels, features, '-v 10 -t 0');

%get A label acc, and non-A label acc
a_acc_sum = 0;
num_as = size(find(labels_test>0),1);
b_acc_sum = 0;
num_bs = size(labels_test,1)-num_as;
for f=1:size(labels_test,1)
    if (labels_test(f)>0)
        if (lte(f) == labels_test(f))
            a_acc_sum = a_acc_sum+1;
        end
    else
        if (lte(f) == labels_test(f))
        	b_acc_sum = b_acc_sum+1;
        end
    end
end

%acc_train
%acc_test
a_acc = a_acc_sum/max([num_as, 1])
b_acc = b_acc_sum/max([num_bs,1])


       