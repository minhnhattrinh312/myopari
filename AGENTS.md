# Repository Guidelines

## Project Structure & Module Organization

Python package code lives under `src/myopari/`. UI entry points are in `_widget.py` and `_segmentation_widget.py`; inference and reporting helpers are under `processors/`. The napari contribution manifest is `src/myopari/napari.yaml`, while bundled ONNX models and label metadata live in `src/myopari/Resources/`. Sample MRI inputs are in `data/`, generated examples in `reports/`, and the LNCS manuscript, bibliography, figures, and class files in `latex/`. `plugin_test.py` is an interactive smoke-test launcher, not an automated unit test.

## Build, Test, and Development Commands

- `python -m venv .venv` then activate it to isolate development dependencies.
- `python -m pip install -e .` installs the plugin in editable mode.
- `pre-commit install` enables repository checks on every commit.
- `pre-commit run --all-files` runs Black, isort, pyupgrade, autoflake, Flake8, and napari plugin checks.
- `python plugin_test.py` opens napari with the segmentation widget for manual verification.
- `python -m build` creates source and wheel distributions in `dist/` (install `build` first).
- From `latex/`, run `latexmk -pdf myopari.tex` to rebuild the manuscript and resolve bibliography passes.

## Coding Style & Naming Conventions

Target Python 3.9 or newer. Use four-space indentation, Black formatting, and a 79-character line length configured in `pyproject.toml`; isort uses the matching Black profile. Use `snake_case` for functions, variables, and modules, `PascalCase` for widget and processor classes, and descriptive napari command IDs such as `myopari.make_segmentation_widget`. Keep changes focused and preserve existing public plugin identifiers.

## Testing Guidelines

There is currently no automated test directory or coverage requirement. For code changes, run all pre-commit hooks and exercise the affected workflow through `plugin_test.py` with an appropriate sample from `data/`. New non-UI logic should include focused pytest tests under `tests/`, named `test_<behavior>.py`. Do not commit generated reports unless they are intentional fixtures or documented examples.

## Commit & Pull Request Guidelines

Recent history uses short, lowercase, imperative subjects such as `add latex docs` and `fix cuda install llama`. Keep each commit scoped to one change. Pull requests should explain the motivation and implementation, list verification commands, link relevant issues, and include screenshots for napari UI changes or rendered pages for manuscript changes. Call out updates to large ONNX models, sample medical images, dependencies, or packaging metadata explicitly.

## Data & Artifact Safety

Use only de-identified sample data. Never commit patient identifiers, credentials, local environments, LaTeX build artifacts, or package outputs. Preserve model provenance and label-map compatibility when changing files in `Resources/`.
