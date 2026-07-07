# CB Requirements — CSV Import Guide

## Files

| File | Rows | Use for |
|------|------|---------|
| `CB_Requirements_UserStories.csv` | 62 user stories | Jira / Azure DevOps backlog import |
| `CB_Requirements_Epics.csv` | 20 epics | Epic / theme planning |
| `CB_Requirements_NFRs.csv` | 10 non-functional requirements | NFR / quality backlog |
| `CB_Requirements_Traceability.csv` | 8 rows | Solution architecture traceability |

Source markdown: [CB_Requirements.md](./CB_Requirements.md)

## Column reference (User Stories)

| Column | Description |
|--------|-------------|
| `Type` | Always `User Story` |
| `Wave` | Wave 1, Wave 2, or Wave 3 |
| `Epic_ID` | E1–E20 |
| `Epic_Name` | Epic title |
| `Feature_ID` | F1.1, F10.2, etc. |
| `Feature_Name` | Feature title |
| `Story_ID` | US-x.x.x (use as external ID / key) |
| `Title` | Short summary for backlog |
| `User_Story` | Full As a / I want / so that |
| `Acceptance_Criteria` | Testable acceptance criteria |
| `Status` | Built, Partial, Not Started |
| `Priority` | Critical, High, Medium, Low |
| `Persona` | Primary actor |
| `Notes` | Implementation hints / artefacts |

## Jira import (Cloud)

1. **Settings → System → External system import → CSV**
2. Map `Story_ID` → Issue Key or External ID
3. Map `Title` → Summary
4. Map `User_Story` → Description
5. Map `Acceptance_Criteria` → Custom field or description appendix
6. Map `Epic_ID` + `Epic_Name` → Epic Link / Epic Name
7. Map `Status` → Jira status (suggested: Built=Done, Partial=In Progress, Not Started=To Do)
8. Map `Priority` → Priority
9. Add label from `Wave` column

## Azure DevOps import

1. **Boards → Queries → Import work items**
2. Map `Type` → Work Item Type (`User Story`)
3. Map `Story_ID` → ID or Tags
4. Map `Title` → Title
5. Map `User_Story` + `Acceptance_Criteria` → Description (HTML)
6. Map `Epic_Name` → Area Path or parent Epic (import Epics CSV first)
7. Map `Status` → State

## Suggested import order

1. `CB_Requirements_Epics.csv` (create epics/themes)
2. `CB_Requirements_NFRs.csv` (create NFR work items)
3. `CB_Requirements_UserStories.csv` (link to epics)
4. `CB_Requirements_Traceability.csv` (attach to wiki / Confluence, not usually imported as work items)

## Status mapping

| CSV Status | Jira | ADO |
|------------|------|-----|
| Built | Done | Closed / Done |
| Partial | In Progress | Active |
| Not Started | To Do | New |
