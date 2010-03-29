Feature: Tree size calulations
  In order to get some feeling for the file size performance
  As a user
  I want to test some traverse operations on Neo4j
 
#  Scenario: Simple tests
#    When I create a filetree with 2 files a 1kb and 1 subfolders in each folder, 3 times nested
#	Then the total number of nodes in the db should be greater than 7
#	Then the total size of one top folder files should be 4 kb and response time less than 0.015 s
 
  Scenario: Bigger data sample
    When I create a filetree with 400 files a 1kb and 50 subfolders in each folder, 3 times nested
	Then the total number of nodes in the db should be greater than 20000
	Then the total size of one top folder files should be 20400 kb and response time less than 0.5 s
 
#  Scenario: Big data sample
#    When I create a filetree with 3000 files a 1kb and 300 subfolders in each folder, 3 times nested
#    Then the total number of nodes in the db should be greater than 20000
#	Then the total size of one top folder files should be 20400 kb and response time less than 0.5 s