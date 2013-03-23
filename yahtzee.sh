#!/bin/bash
# Yahtzee is a terminal version of the game yahtzee.
#     Copyright (C) 2013 Vijay Thurimella

#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.

#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.

#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.

declare -a board
declare -a section 
declare store
declare score
declare pick
declare name
declare lower_total
declare got_yahtzee
declare YNUM

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
  lower_total=0
  has_yahtzee=""
  YNUM=12
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
  if is_used "${section[$1]}"; then
   echo "$(echo ${section[$1]} | cut -dX -f1)already picked"
   return 0
  else
    temp=$(compute_score $1)
    score=$(($score + $temp))
    if [[ 1 -le $1 && $1 -le 6 ]]; then
      lower_score=$(($lower_score + $temp))
    fi
    section[$1]="$(echo ${section[$1]} | cut -d "-" -f1) X"
    return 1
  fi
}

is_used(){
  echo $1 | grep "X" >> /dev/null 
  return $?
}

print_used(){
  local used
  local i
  used="Used: "
  for ((i=1; i<=13; i++)); do
    if is_used "${section[$i]}"; then
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
  len1=$(comm -12 <(echo {1..4} | xargs -n1) \
          <(echo ${board[@]} | xargs -n1 | sort -n) | wc -l)
  len2=$(comm -12 <(echo {2..5} | xargs -n1) \
          <(echo ${board[@]} | xargs -n1 | sort -n) | wc -l)
  len3=$(comm -12 <(echo {3..6} | xargs -n1) \
          <(echo ${board[@]} | xargs -n1 | sort -n) | wc -l)
  if [[ $len1 -eq 4 || $len2 -eq 4 || $len3 -eq 4 ]]; then
    return 0
  fi
  return 1
}

has_largestraight(){
  local len1
  local len2
  len1=$(comm -12 <(echo {1..5} | xargs -n1) \
          <(echo ${board[@]} | xargs -n1 | sort -n) | wc -l)
  len2=$(comm -12 <(echo {2..6} | xargs -n1) \
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
  num=${board[0]}
  case $1 in
    [1-6]) echo $(($1 * $(count_numbers $1)));;
    7) if has_n 3 || has_n 4 || has_n 5; then
         echo $(sum_board)
       else
          echo 0
       fi
       ;;
    8) if has_n 4 || has_n 5; then
         echo $(sum_board)
       else
         echo 0
       fi
       ;;
    9) if has_fullhouse; then
         echo 25
       else 
          if is_used "${section[YNUM]}" && has_n 5 && is_used "${section[num]}";
          then
            echo 25
          else
            echo 0
          fi 
       fi
       ;;
    10) if has_shortstraight; then
          echo 30
        else
          if is_used "${section[YNUM]}" && has_n 5 && is_used "${section[num]}";
          then
            echo 30
          else
            echo 0
          fi 
        fi
        ;;
    11) if has_largestraight; then
          echo 40
        else
          if is_used "${section[YNUM]}" && has_n 5 && is_used "${section[num]}";
          then
            echo 30
          else
            echo 0
          fi 
        fi
        ;;
    12) if has_n 5; then
         echo 50
         got_yahtzee=1
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
    board[$i]=$(echo "($RANDOM % 6) + 1" | bc)
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
      read -p "Hold which dies (\"skip\" to score): " store
      if [[ -n $store && $store = "skip" ]]; then
        store=$(echo {1..5})
        j=1
      else
        store=$(echo ${store//[^0-9]/ })
      fi
      store=$(difference "$store")
   else
      clear
      echo "Dice   ------> " ${board[@]}
      if [[ -n got_yahtzee && "has_n 5" ]]; then
        echo "Yahtzee Bonus"
        score=$(($score + 100))
      fi
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

clear
if [[ 63 -le $lower_score ]]; then
  echo "Received upper bonus!"
  score=$(($score + 35))
fi

read -p "Enter first name: " name
while [ -z "$name" ]; do
  read -p "Enter first name: " name
done
echo "$name $score" >> .yahtzee_scoreboard.txt

cat .yahtzee_scoreboard.txt | sort -r -k2 -n | head -10 >> .yaht_score_sorted
mv .yaht_score_sorted .yahtzee_scoreboard.txt

echo "Scoreboard"
cat .yahtzee_scoreboard.txt
