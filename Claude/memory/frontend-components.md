# Frontend components

How to shape UI components so a screen reads top-down and stays easy to change.

## Size and split

- **Small reusable pieces, not one big component.** Generic presentational pieces take
  plain props (a section header, a card row); thin feature components compose them.
  About 150 lines at most per component, no nested ternaries, early returns, named handlers.
  *Why: a reviewer has to see what a component does in one screen.*
- **Data in hooks, logic in pure functions, components only render.**

## Component shape

- **The main component reads as an outline of the screen.** Hooks at the top, then one
  child component per section, then dialogs:

  ```tsx
  const CourseForm = ({ detail }: CourseFormProps) => {
    const { form, trackUpload } = useCourseFormContext()
    const title = useWatch({ control: form.control, name: 'title' })

    return (
      <Paper component="form">
        <CourseInfoSection control={form.control} title={title} … />
        <CourseDetailSection control={form.control} title={title} … />
      </Paper>
    )
  }
  ```

- **Sections live at module level or in their own file — never inside another component's
  body.** Export a section only when another file uses it.
  *Why: a component defined during render is a new type every render, so the framework
  remounts it — an input loses focus on each keystroke and local state (an upload in
  progress) resets. If the user sketches inner components, build them outside and say why.*
- **No render-function props for layout** (`renderLayout(content, footer)`). The page or
  screen component is the layout: it renders header, tabs, content and footer itself, and
  each mode's footer is its own component.
  *Why: a layout function built inside the page is hard to follow; turning it into a
  component defined inside the page remounts everything under it.*
- **State that content and footer both need goes in a provider/context**, read by each —
  not passed back up through callback props such as `onDirtyChange`.
  *Why: the page can then read the same state directly, and the callbacks disappear.*

## Layout

- **Fields that must line up share one grid.** Use one `repeat(4, minmax(0, 1fr))` grid and
  span wide fields, never two grids with different track counts.
  *Why: `fr` splits the space left after the gaps, so a 3-track row above a 4-track row
  never aligns; plain `1fr` also lets long content widen its column.*
