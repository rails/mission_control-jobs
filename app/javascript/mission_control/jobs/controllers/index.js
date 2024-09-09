import { application } from "mcj-controllers/application"
import { eagerLoadControllersFrom } from "mcj-@hotwired/stimulus-loading"

eagerLoadControllersFrom("controllers", application)
