#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

INPUT_NAME() {
  echo "Enter your username:"
  read NAME
  n=${#NAME}

  #When you run your script, you should prompt the user for a username with Enter your username:, and take a username as input.Your database should allow usernames that are 22 characters
  if [[ ! $n -le 22 ]] || [[ ! $n -gt 0 ]]
  then
    INPUT_NAME
  else
    USER_NAME=$(echo $($PSQL "SELECT username FROM users WHERE username='$NAME';") | sed 's/ //g')
    if [[ ! -z $USER_NAME ]]
    then
      #If that username has been used before, it should print Welcome back, <username>! You have played <games_played> games, and your best game took <best_game> guesses., 
      #with <username> being a users name from the database,
      #<games_played> being the total number of games that user has played, 
      #and <best_game> being the fewest number of guesses it took that user to win the game
      USER_ID=$(echo $($PSQL "SELECT user_id FROM users WHERE username='$USER_NAME';") | sed 's/ //g')
      USER_NAME=$(echo $($PSQL "SELECT username FROM users WHERE user_id='$USER_ID';") | sed 's/ //g')
      GAME_PLAYED=$(echo $($PSQL "SELECT frequent_games FROM users WHERE user_id=$USER_ID;") | sed 's/ //g')
      BEST_GAME=$(echo $($PSQL "SELECT MIN(best_guess) FROM users LEFT JOIN games USING(user_id) WHERE user_id=$USER_ID;") | sed 's/ //g')
      echo "Welcome back, $USER_NAME! You have played $GAME_PLAYED games, and your best game took $BEST_GAME guesses."
    else
      #If the username has not been used before, you should print Welcome, <username>! It looks like this is your first time here.
      USER_NAME=$NAME
      echo -e "\nWelcome, $USER_NAME! It looks like this is your first time here."
    fi

    #Your script should randomly generate a number that users have to guess
    #The next line printed should be Guess the secret number between 1 and 1000: and input from the user should be read
    CORRECT_ANSWER=$(( $RANDOM % 1000 + 1 ))
    GUESS_COUNT=0
    INPUT_GUESS $USER_NAME $CORRECT_ANSWER $GUESS_COUNT
  fi
}

INPUT_GUESS() {
  USER_NAME=$1
  CORRECT_ANSWER=$2
  GUESS_COUNT=$3
  USSER_GUESS=$4

  if [[ -z $USSER_GUESS ]]
  then
    echo "Guess the secret number between 1 and 1000:"
    read USSER_GUESS
  else
    #If anything other than an integer is input as a guess, it should print That is not an integer, guess again:
    echo "That is not an integer, guess again:"
    read USSER_GUESS
  fi

  GUESS_COUNT=$(( $GUESS_COUNT + 1 ))
  if [[ ! $USSER_GUESS =~ ^[0-9]+$ ]]
  then
    INPUT_GUESS $USER_NAME $CORRECT_ANSWER $GUESS_COUNT $USSER_GUESS
  else
    CHECK_ANSWER $USER_NAME $CORRECT_ANSWER $GUESS_COUNT $USSER_GUESS
  fi
}

CHECK_ANSWER() {
  USER_NAME=$1
  CORRECT_ANSWER=$2
  GUESS_COUNT=$3
  USER_GUESS=$4

  while true; do
    if [[ ! $USER_GUESS =~ ^[0-9]+$ ]]; then
      echo "Invalid input. Please enter a number:"
    elif [[ $USER_GUESS -lt $CORRECT_ANSWER ]]; then
      echo "It's higher than that, guess again:"
    elif [[ $USER_GUESS -gt $CORRECT_ANSWER ]]; then
      echo "It's lower than that, guess again:"
    else
      echo "You guessed it in $GUESS_COUNT tries. The secret number was $CORRECT_ANSWER. Nice job!"
      SAVE_USER "$USER_NAME" "$GUESS_COUNT"
      break
    fi

    read -p "> " USER_GUESS
    ((GUESS_COUNT++))
  done
}


SAVE_USER() {
  USER_NAME=$1 
  GUESS_COUNT=$2

  CHECK_NAME=$($PSQL "SELECT username FROM users WHERE username='$USER_NAME';")
  if [[ -z $CHECK_NAME ]]
  then
    INSERT_NEW_USER=$($PSQL "INSERT INTO users(username, frequent_games) VALUES('$USER_NAME',1);")
  else
    GET_GAME_PLAYED=$(( $($PSQL "SELECT frequent_games FROM users WHERE username='$USER_NAME';") + 1))
    UPDATE_EXIST_USER=$($PSQL "UPDATE users SET frequent_games=$GET_GAME_PLAYED WHERE username='$USER_NAME';")
  fi
  SAVE_GAME $USER_NAME $GUESS_COUNT
}

SAVE_GAME() {
  USER_NAME=$1 
  NUMBER_OF_GUESSES=$2

  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USER_NAME';")
  INSERT_GAME=$($PSQL "INSERT INTO games(user_id, best_guess) VALUES($USER_ID, $NUMBER_OF_GUESSES);")
  USER_NAME=$($PSQL "SELECT username FROM users WHERE user_id=$USER_ID;")
}

INPUT_NAME