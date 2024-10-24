extends Node

var Player1Active = true #Player position 1 is playing or not
var Player1Score = 0  #Player position 1's score

var Player2Active = false #Player position 2 is playing or not
var Player2Score = 0  #Player position 2's score

var Player3Active = false #Player position 3 is playing or not
var Player3Score = 0  #Player position 3's score

var Player4Active = false #Player position 4 is playing or not
var Player4Score = 0  #Player position 4's score

var CurrentQuizQuestions = [] #The questions to be used in the current quiz
var CurrentQuestionIndex = 0 #The index of question currently on in quiz

var TagsToExclude = [] #The list of tags to be excluded from quizes

var CurrentTheme = "default" #The current quiz theme
