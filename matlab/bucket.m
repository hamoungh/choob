function [bucket,total] = bucket(buckets, values)
% Create an Array of values and buckets
A = cat(2,values, buckets);
% Sort the array on the buckets
B = sortrows(A,2);
sortedbuckets=B(:,2);
% Get the number of elements in the array
n=size(sortedbuckets,1);
% Set distinctbuckets to be different buckets. Initially, all the same
distinctbuckets(1:n) = 1;
% Then, compare the elements of the buckets with the values immediately following
distinctbuckets(2:n) = ( sortedbuckets(1:n-1) ~= sortedbuckets(2:n) );
% cumsum does a cumulative sum. As long as the bucket values are the same, the value
% in distinctbuckets will be zero and the resulting uniquebucket stays the same.
% when they are different, the value is 1 and the uniquebuckets are incremented by 1
uniquebuckets=cumsum(distinctbuckets);
% This results in an index we can use for accumarry. We store the results in total
total=accumarray(uniquebuckets',B(:,1));
% And the bucket value is the unique sorted bucket values
bucket=unique(B(:,2));
return;