echo "Executing prepush script"

printf "Generating markdown files corresponding to tags in posts... "
python ./lib/tag_generation.py
printf "[DONE]\n"

echo "Prepush script execution complete, ready to push to VCS."