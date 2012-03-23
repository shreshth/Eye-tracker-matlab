1). The directory where this file resides constitutes the "main" directory

2). The high-level directory structure is as follows:

    main/img/videoXXXX  - contains all the test videos to be used by the code
    main/img/videoTrain - contains all the training videos used by the code
    main/results        - contains some output plots
    main/documents      - contains documentations/writeup for our eyeTracker

3). In order to run the code, use the RUNME.m file. 

    You need to control the parameter interface there and can also for the 
    main function trackEyes()

4). The algorithm used for each of the above problems is well documented
    within the source files. We have just followed the instructions step-
    by-step mentioned in our writeup and code. Hence, we feel it redundant 
    to repeat the steps here. 

5). Type the following commands to know about the list of arguments

    help trackEyes;
    help eigenEyes;
    help svmRecognition;