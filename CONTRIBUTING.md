# Contributing to Power Balance Models

## Python Poetry :closed_book:

As mentioned in the [README](./README.md) for this repository, it is strongly recommended that you use Poetry for
development. The included `pyproject.toml` and `poetry.lock` files ensure that those using the tool are running
the `power_balance` module in an identical manner. Before any releases are made this provides the fastest and easiest
way to get started.

Poetry can be installed using `pip` or an installer script, further documentation for the tool is available on the
project's [website](https://python-poetry.org/docs/).

`poetry` creates a virtual environment containing specific versions of the prerequisite Python packages. Then, by
using `poetry run <command>` the developer may run `<command>` inside that virtual environment instead. You can
do `poetry run pip` as well and tamper with the packages inside the environment as well, if needed.

## Setting up for development on the Power Balance Models :question:

1. Make sure you have installed `poetry` (see above), OpenModelica (v1.16.2 advised), Git, and obviously Python (v3.8
   advised).

2. Clone the repository to a folder of your choosing on your PC. Make sure that the absolute path to that folder does
   NOT contain any spaces:

   :x: `C:/Program Files/Git/powerbalance/`

   :heavy_check_mark: `C:/TokamakScience/Git/powerbalance/`

   Spaces may cause issues with running the program in development mode.

3. While inside the local repository, perform `poetry install`.

4. If the above step completes without errors, you will then be able to type in `poetry run powerbalance`, and if the
   installation is successful you will be met with a help text and a list of commands.

5. Perform a test run to ensure that everything is running as intended: `poetry run powerbalance run`

If there are any errors you do not understand or are unable to solve, make sure to open an issue.

## Setting up the git pre-hooks :hook:
This repository contains a configuration for the `pre-commit` git hook setup tool. It is strongly recommended that you install these hooks to ensure your commits pass quality control before you push them to GitHub. `pre-commit` is already available within the poetry virtual environment, the hooks are installed by running:
```sh
pre-commit install
```
and are updated using:
```sh
pre-commit autoupdate
```
further information on `pre-commit` can be found on [here](https://pre-commit.com/).

## How to contribute effectively :exclamation:

These practices should be followed as the effect of not doing so may delay implementation and mean more tedious work for
you.

1. Firstly, some basic rules about the use of Git.
    * Always do `git fetch`. This will ensure your local Git knows about all the changes that have happened on the
      remote. The command will also tell you if there are changes or not. You must do this every day when you start
      work. Changes can occurr 'overnight' and it is your responsibility to keep yourself up-to-date with new commits.
    * If there are changes on a branch called >name<, you **must** pull while having the branch checked out:
       ```sh
       git checkout >name<
       git pull
       ```
    * If you fail to do so, and then clone branches or rebase, you might find yourself having to redo your work, or in
      the worst case - end up producing wrong data because you worked on an outdated, error-prone version of the
      software.
    * Use `git diff` to inspect your changes before committing. If there are changes that you did not make (for example,
      OpenModelica likes to insert its own changes sometimes), you would probably do well by reverting these undesired
      changes.
    * Use `git status` to keep track of what files you have modified and what files are staged for committing, and also
      to check whether your local branch is up to date with the the remote or not.
    * If there's terminology about Git that you do not understand, I suggest that you enrol on a 'Git basics' course on
      Unit4 or look up Git tutorials online.


2. For each bug fix or feature, open a new branch by cloning off the latest version of the `main` branch.
   Any additions or changes to the codebase should be added into `main` via a Merge Request.

   Make sure the branch is named appropriately to describe the changes the branch will introduce, or the branch's
   purpose, e.g.:

   :x: `testing`

   :x: `test-subv-mod-str-param`

   :heavy_check_mark: `testing-subverting-modelica-structural-params`

3. Create a merge request from your branch into `main`. If you are still actively working on the branch set it to be a draft by clicking `Convert to draft` in the `Reviewers` side menu. Make sure to give it a meaningful title that illustrates
   what the purpose of the merge request is, then describe the changes added inside the body. Explain what you've done
   and why it is needed, don't copy the commit messages or the code - we can see your code snippets and commits.

4. Update Changelog with significant changes. Do not copy and paste `git log` outputs to the `CHANGELOG.md`. This should
   be a user friendly brief summary of the change you are implementing if it is significant:

   :x: `* Fixed HCD model issue.`

   :x: `* Fixed typo in run script.`

   :heavy_check_mark: `* Corrected HCD models to use type B for calculations as opposed to type A.`

5. When editing or writing new code in Modelica, ensure to maintain the style and formatting. Issues with style and
   formatting will be flagged and sent back to you for corrections.
    - Editing Modelica models using the graphics interface (Diagram View) in OMEdit is prone to issues, namely:

        ```sh
        Scripting Warning
        Could not preserve the formatting of the model instead internal pretty-printing algorithm is used.
        ``` 

      If this warning appears in your console (with orange text), the formatting and styling of the file you are working
      with has been changed by OMEdit. You **must NOT save** the file you were working on - instead close OMEdit
      discarding all changes, then re-open the model and re-insert your work using Text View. The so-called "pretty
      printing" algorithm creates a lot of issues with readability, and if these issues persist in your final work, you
      will be asked to correct them before your work can be merged.

    - Keep the same type of declaration in 'zones'. This means:
        - keep parameters grouped together, separate from variables;
        - keep parameters/variables relating to one part of the system, such as one coil or one heat exchanger, next to
          each other;
        - keep all model instatiations together;
        - maintain readability by providing spacing between the different groups using new lines and `//`.

    - All parameters and variables must contain an appropriate unit, preferably in SI but always in metric. The unit can
      be defined either by using built-in Modelica types such as `Modelica.SIunits.Resistance` or declaring your own
      unit such as `parameter R(unit = "Ohm")`. The unit declaration must not have any spaces, you can use a dot `.` to
      indicate multiplication - as in `J/(kg.K)`. Unit declarations must also not contain the `%` sign.

    - All parameters must be named appropriately for their purpose, balancing the length of the name with how
      descriptive it is. Additonally, a certain standard for their formatting must be maintained in the
      format `firstwordSecondwordThirdword_optionalClarification`:

      :x: `coil_l_pf1`

      :x: `coil_length_pf1`

      :heavy_check_mark: `coilLength_PF1`

    - Parameters starting with double underscore e.g. `__numTurns` are intended for setting from outside the Modelica
      editor.

6. When editing or writing new code in Python, ensure to follow the style already laid out in the existing Python files.
   Give your functions appropriate descriptions.

7. Before finalising your work, check whether there's any changes made to `main` since you cloned your branch. If
   there are, you should pull these chages and merge `main` checking to see if there are any conflicts.
   The merge conflicts must be resolved before your branch can be merged
   into `main`. Seek assistance if you do not know what must stay and what must go. If you are working on a branch
   for a while, it is a good idea to merge regularly in order to avoid having dozens of conflicts at the end.

8. Make a final update to the title and body of the merge request - does what you wrote when you made the request still
   reflect the work done? Add detail and clarify any vague statements.

9. Notify a maintainer that the merge request is ready for merging.

## Read documentation

Make sure you have read and understood
the [Developer Documentation](https://ukaea.github.io/powerbalance/API/development/).

## See a problem? Open an Issue! :warning:

If you see any problems with the code, no matter how small, or you have any suggestions on how to improve it/additions
you would like the best way to draw attention to them is to open an issue.

## See an Issue you want to handle? Assign yourself :pencil2:

The best way to keep track of who is doing what is for everyone to create issues for what they are planning to work on
and to assign themselves to that issue.

Furthermore it is recommended that you create a new branch for every issue you work on, consider prefixing your branch with `<issue-number>-`, e.g. `19-added-documentation` as a branch name. Also consider attaching merge requests to relevant issues.

## Feel free to discuss :speech_balloon:

If you feel a discussion could benefit the project as a whole, use the [Discussions](https://github.com/ukaea/powerbalance/discussions) area to talk about any non-issue related topics on the project.

## Milestones and Labels are important :running:

Labels are assignable to issues and Merge Requests and are an important indication of the category. GitHub provides
existing labels such as `bug` and `documentation` but others can be created. In addition please assign either the
label `API Development` or `Model Development` where applicable.

Milestones collect issues into a subgroup relating to a particular objective to be reached. These can be given deadline
dates and also have the bonus of creating new project boards to display the status of that objective.

## Testing is essential :heavy_check_mark:

As with any bit of research software, results are only as reliable as the codebase they come from. If you add a new
feature to the Python API you should consider writing a test to verify the behaviour is as expected. See the
existing [tests](https://github.com/ukaea/powerbalance/tree/main/tests) directory for
examples.

## Update the Changelog with releases

Whenever a new release is made please ensure it is tagged and the tag matches [semantic versioning](https://semver.org).

Update the [CHANGELOG](./CHANGELOG.md) to give the date of the release.
