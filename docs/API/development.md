# Development

Contributions to the Power Balance Models (PBM) project can be broken down into model development and API development. Both should be performed under git version control with changes being committed to a personal development branch, and any conflicts being resolved before merging into the main `develop` branch takes place. 

It is recommended you develop and test PBM using UV, instructions on how to install and run the project this way are given [here](uv.md).

The terms "backend" and "frontend" are used to refer to the OpenModelica and Python code respectively.

## Model Development

When updating revisions of the model components make sure to add the revision to the documentation page for that component, e.g. for `Tokamak.Magnets.TF_Magnet` [here](../modelica/tfcoil/#revisions).

!!! warning "Model Merge Conflicts"
    Special care should be taken to ensure any conflicts raised during a git merge are addressed. If such conflicts appear within the Modelica files it is strongly recommended that you either use the script view in OMEdit or another editor to address them.

## API Development
Where possible any new features should either be placed within a relevant existing location, or should form a new subdirectory in the python module. For example, any additions relating to compatibility with external data sources could be added to a new location `power_balance/external_data`.

A unit/regression test for each new feature should be added to the `tests` directory (See [Testing](#testing)).

The code should be documented sensibly. As a tip, imagine you are returning to the code after a year, what comments would help you remember how to use your code?

Try to use typing in your functions. Not only does this improve readability, but if you run `uv run mypy` it will tell you if the object type a function is returning matches your expectation. An example typed function would be:

``` python
from typing import Dict
from string import ascii_lowercase

def my_useless_function(a: int, b: int) -> str:
    temp_var_ : Dict[int, str] = {}

    for i in range(a, b):
        temp_var_[i] = ascii_lowercase[i % 3]

    return ''.join(temp_var_.values())

```

more information on `mypy` can be found [here](http://mypy-lang.org/).

## Testing
### Unit and Regression Testing
Testing is essential to ensuring the outputs from PBM are accurate and the code behaves as expected. Tests are performed using `pytest` and are usually of the following form:

- If the code addition is being added to an existing feature create a test in the tests script for that feature else create a new one within `tests`.
- Test files must start with the prefix `test_`.
- Use `pytest.mark` to help categorise tests.
- Use `pytest.fixture` for test setup (e.g. creating an instance of a class that should be shared between all tests)

As an example say we have a new feature "User Greetings", a test script would be created `tests/unit_tests/test_user_greeting.py`:

```python
import pytest

from power_balance.greetings import Greeter


# Create an instance of the fictional Greeting class
# to be shared between all tests within this module (script)
@pytest.fixture(scope="module")
def greeter_instance():
    return Greeter(name="John")


# Add the test to the category "greetings"
# pass fixture as argument
@pytest.mark.greetings
def test_greeter_message(greeter_instance):
    # Check that we get what we expect
    assert greeter_instance.message() == "Hello John!"

```

We also need to add the new category to the `pytest.ini` file:
```ini
[pytest]
markers=
    greetings: tests related to the greetings submodule
```

??? question "Unit or Regression?"

    Unit tests and regression tests are very different things. A unit test is a test which asserts that the code behaves as we expect (usually as the literature/science dictates). For example:

    ```python
    def adder(a, b):
        return a + b

    # We know 2+3 should equal 5 so we check our code
    # behaves as such
    def test_adder():
        assert adder(2, 3) == 5
    ```

    However a regression test checks that the code behaves the same now as it did previously, in the case of PBM the folder `baseline` contains data collected during a run which is known to be correct. Using the previous example:

    ```python
    def adder(a, b):
        return a + b

    def test_adder():
        with open('previous_run_data.npy', 'rb') as f:
            assert adder(2, 3) == np.load(f)
    ```

### Benchmark Testing
Performance of PBM is measured using [airspeed-velocity](asv.readthedocs.io/) (ASV) which allows the user to write tests for measuring properties such as the timing and memory usage during execution. These tests are grouped in "suites" which are classes containing similar category tests. For PBM these can be found in the `benchmarks` directory, the Python scripts containing tests which are grouped as either timing or memory tests. ASV identifies the type of test from the prefix, `time_` for timing tests, `mem_` for memory tests.

For timing a function a simple test would be:
```python
from my_module import a_very_long_process

# As these are timing tests we shall group them in the same class/suite
class TimingSuite:
    def setup(self):
        # we can put any setup for the tests in here
        pass

    def time_long_process(self):
        a_very_long_process()
```
See the ASV [documentation](asv.readthedocs.io/) for more details.

## Semantic Versioning
PBM where possible keeps to a strict following of the semantic versioning standard outlined [here](https://semver.org/). It is strongly recommended you read these standards before creating a new release. The most important points being:

- "Once a versioned package has been released, the contents of that version MUST NOT be modified. Any modifications MUST be released as a new version."
- The importance of numbering `X.Y.Z` representing MAJOR, MINOR, PATCH. A good illustration of the difference between these is shown [here](https://medium.com/fiverr-engineering/major-minor-patch-a5298e2e1798).

!!! note "Pre-Release"
    Note versions prior to `v1.0.0` may follow a looser standard.

## Using Git Prehooks
It is strongly recommended that the pre-commit git hooks be installed to catch any issues with code quality, file size and merge conflict remnants. In order to install the git hooks within the repository install `pre-commit` via pip (this is already present if using `uv` to develop), and run:
```sh
pre-commit install
```
to update your local `.git/hooks/pre-commit` file. Whenever you create a commit if there are any issues with it these will be flagged before you are allowed to continue.
