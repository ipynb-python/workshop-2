# Workshop 2

Please find the instructions for this workshop here: 

https://github.com/ipynb-python/Workshop-2-Instructions/blob/main/README.md

You can run each file using the terminal e.g.

```sh
python workshop2_part1.py
```

The expected outputs of each code file can be found in the `ref_output` folder.

Run the grading script to check your code by entering the following command in the terminal.

```sh
bash grade_workshop.sh
```

After completing the exercises please run the following commands in the terminal.

These lines will save your code in three stages:
 - modified files are staged to specify which changes will be commited;
 - staged changes are committed to the local git code repository (on the CodeSpace machine)
 - changes are pushed to the remote master copy of the code repository on GitHub website

```sh
git add .
git commit -m "finished exercises"
git push
```

It is a good habit to commit and push your files everytime you have made a significant change. In this case you can change the commit message, e.g. `git commit -m "completed workshop2_part1.py"`.
