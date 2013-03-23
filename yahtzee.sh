#!/bin/bash
declare -a board
declare -a section 
declare store
declare score
declare pick
declare name

init(){
  section[1]="Ones "
  section[2]="Twos "
  section[3]="Threes "
  section[4]="Fours "
  section[5]="Fives "
  section[6]="Sixes "

  section[7]="Three Of A Kind "
  section[8]="Four Of A Kind "
  section[9]="Full House "
  section[10]="Small Straight "
  section[11]="Large Straight "
  section[12]="Yahtzee "
  section[13]="Chance "
  score=0
}

update_section(){
  local i
  for ((i=1; i<=13; i++)); do
    section[$i]=$(echo ${section[$i]} | cut -d "-" -f1)
    if ! echo ${section[$i]} | grep "X" >> /dev/null; then
      section[$i]="${section[$i]} - $(compute_score $i)"
    fi
  done
}

count_numbers(){
  local count=0
  local i
  for ((i=0; i<5; i++)); do
    if [ ${board[$i]} -eq $1 ]; then
      ((count++))
    fi
  done
  echo $count
}

pick_section(){
  if [ $(echo -n $1 | wc -c) -eq 0 ]; then
    read -p "Pick which Section: " s
    pick_section $s
    return $?
  fi
  if ! echo {0..13} | xargs -n1 | grep $1 >> /dev/null; then
    read -p "Pick which Section: " s
    pick_section $s
    return $?
  fi
  if echo ${section[$1]} | grep "X" >> /dev/null; then
   echo "$(echo ${section[$1]} | cut -dX -f1)already picked"
   return 0
  else
    temp=$(compute_score $1)
    score=$(($score + $temp))
    section[$1]="$(echo ${section[$1]} | cut -d "-" -f1) X"
    return 1
  fi
}

print_used(){
  local used
  local i
  used="Used: "
  for ((i=1; i<=13; i++)); do
    if echo ${section[$i]} | grep "X" >> /dev/null; then
      used="$used$(echo ${section[$i]} | cut -d X -f1 | tr -d " "), "
    fi
  done
  len=${#used}
  echo ${used:0:$len-2}
}

sum_board(){
  local sum
  local i
  sum=0
  for i in {0..4}; do
    sum=$(($sum + ${board[$i]}))
  done
  echo $sum
}

has_n(){
  local i
  for i in {1..6};do
    if [ $(echo ${board[@]} | xargs -n1 | grep $i | wc -l) -eq $1 ]; then
      return 0
    fi
  done
  return 1
}

has_shortstraight(){
  local len1
  local len2
  local len3
  len1=$(comm -12 <(echo "1 2 3 4" | xargs -n1) \
          <(echo ${board[@]} | xargs -n1 | sort -n) | wc -l)
  len2=$(comm -12 <(echo "2 3 4 5" | xargs -n1) \
          <(echo ${board[@]} | xargs -n1 | sort -n) | wc -l)
  len3=$(comm -12 <(echo "3 4 5 6" | xargs -n1) \
          <(echo ${board[@]} | xargs -n1 | sort -n) | wc -l)
  if [[ $len1 -eq 4 || $len2 -eq 4 || $len3 -eq 4 ]]; then
    return 0
  fi
  return 1
}

has_largestraight(){
  local len1
  local len2
  len1=$(comm -12 <(echo "1 2 3 4 5" | xargs -n1) \
          <(echo ${board[@]} | xargs -n1 | sort -n) | wc -l)
  len2=$(comm -12 <(echo "2 3 4 5 6" | xargs -n1) \
          <(echo ${board[@]} | xargs -n1 | sort -n) | wc -l)
  if [[ $len1 -eq 5 || $len2 -eq 5 ]]; then
    return 0
  fi
  return 1
}

has_fullhouse(){
  if has_n 4; then
    return 1
  fi
  if [ $(echo ${board[@]} | xargs -n1 | sort -n | uniq | wc -l) -eq 2 ]; then
    return 0
  fi
  return 1
}

compute_score(){
  case $1 in
    [1-6]) echo $(($1 * $(count_numbers $1)));;
    7) if has_n 3 || has_n 4; then
         echo $(sum_board)
       else
         echo 0
       fi
       ;;
    8) if has_n 4; then
         echo $(sum_board)
       else
         echo 0
       fi
       ;;
    9) if has_fullhouse; then
         echo 25
       else 
         echo 0
       fi
       ;;
    10) if has_shortstraight; then
          echo 30
        else
          echo 0
        fi
        ;;
    11) if has_largestraight; then
          echo 40
        else
          echo 0
        fi
        ;;
    12) if has_n 5; then
         echo 50
       else
         echo 0
       fi
       ;;
    13) echo $(sum_board)
        ;;
    *) echo "";; 

  esac
}

print_section(){
  echo "Upper Section"
  local i
  for ((i=1; i <= 6; i++)); do
    echo $i ${section[$i]}
  done
  echo "Lower Section"
  for ((i=7; i <= 13; i++)); do
    echo $i ${section[$i]}
  done
}

difference(){
  comm -23 <(echo "0 1 2 3 4" | xargs -n1)  \
   <(echo $1 | xargs -n1 | sort -n | awk '{print $1 - 1}')
}

roll(){
  local i
  for i in $(echo $store); do
    board[$i]=$(($(($RANDOM % 6)) + 1))
  done
}

init
for ((i=1; i<=13; i++)); do
  store=$(echo {0..4})
  for ((j=0; j<3; j++)); do
      roll $store
      echo "Dice   ------> " ${board[@]}
      echo "Hold Labels -> " {1..5}
    if [ $j -ne 2 ]; then
      read -p "Hold which dies (\"skip\" to score current): " store
      if [[ -n $store &&  $store = "skip" ]]; then
        store=$(echo {1..5})
        j=1
      else
        store=$(echo ${store//[^0-9]/ })
      fi
      store=$(difference "$store")
   else
      clear
      echo "Dice   ------> " ${board[@]}
      update_section
      print_section
      read -p "Pick which Section: " pick
      while pick_section $pick; do
        read -p "Pick which Section: " pick
      done
      clear
      print_used
      echo "Score: $score"
    fi
  done
done

read -p "Enter first name: " name
while [ -z "$name" ]; do
  read -p "Enter first name: " name
done
echo "$name $score" >> .yatzee_scoreboard.txt

cat .yatzee_scoreboard.txt | sort -r -k2 -n | head -10 >> .yat_score_sorted
mv .yat_score_sorted .yatzee_scoreboard.txt

echo "Scoreboard"
cat .yatzee_scoreboard.txt
