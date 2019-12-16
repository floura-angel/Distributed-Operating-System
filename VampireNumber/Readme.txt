Note:

We tried implementing the solution for Vampire Number using Actor model in two methods

SaxenaNadar: Here, we tried using 
Boss.ex - Main function using Genserver to distribute the workload and print the fangs together
Worker.ex - The worker function using Genserver to perform computation 
Backup.ex - To supervise the worker module

SaxenaNadar_optional: Here, we tried using Task.async, getting fangs from the function using cast function in one Genserver and at the end of all task.async functions, use of call method to display the list of fangs. Same module for boss and worker. 

Files included:
1. SaxenaNadar.zip
2. SaxenaNadar_optional.zip
3. Project1_Report_1.pdf
4. Readme.txt