* set working directory
cd "/Users/jp4096/Documents/RMCodingAssignments/Assignment4"

* upload file
import delimited "/Users/jp4096/Documents/RMCodingAssignments/assignment4/crime-iv.csv"

* install packages
ssc install table1
ssc install outreg
ssc install estout
ssc install ivreg2
ssc install ranktest

* label variables 
label variable defendantid "Defendant ID"
label variable republicanjudge "Republican Judge"
label variable severityofcrime "Severity of Crime"
label variable monthsinjail "Months in Jail"

* Question 1: 
* Obama's "cycle of crime" theory implicitly assumes that the value of the dependent variables' error terms are independent of predictor variables. But, this may not be the case, and there may be an endogeneity issue. This is because people who commit crimes may actually be likely to reoffend anyway, regardless of how harsh their sentence is. We have to have more evidence to conclude that "harsh sentencing is creating more criminals" because it could be that criminals are the ones who receive the harshest sentences. Moreover, other factors that are not being controlled for, such as income, poverty, personal circumstances, that are highly connected with the outcome and explanatory variables could be contributing to some of this problem. 


* Question 2:
* My friend's research design suffers from the endogeneity problem because the regressor, the length of the prison sentence, and the outcome variable, recidivism are probably jointly dependent on another factor that's not been controlled for (an error term). For instance, one variable that's not included in the dataset that could be related to both the main explanatory variable and outcome variable is personal circumstances, such as poverty. There is much evidence that impoverished circumstances can drive people to repeated (recidivsm), violent (which obviously relates to the length of sentence) crime. We'd need instrumental variables to correct for this endogeneity problem. 

*It's also worth noting that there may be a reverse causality problem. We dont' know if the explanatory variable, length of prison sentence, explains recidivism, or it's the other way around. In fact, we could argue that it is the other way around, since people who continuously offend will probably receive longer prison sentences.*


* Question 4: do balance table / do balance test 
iebaltab severityofcrime monthsinjail recidivates, grpvar(republicanjudge) save(assignment4)

* more complicated way that takes too long
* make tables of descriptive statistics 
global DESCVARS severityofcrime monthsinjail recidivates
mata: mata clear

* First test of differences
local i = 1


foreach var in $DESCVARS {
    reg `var' republicanjudge
    outreg, keep(republicanjudge)  rtitle("`: var label `var''") stats(b) ///
        noautosumm store(row`i')  starlevels(10 5 1) starloc(1)
    outreg, replay(diff) append(row`i') ctitles("",Difference ) ///
        store(diff) note("")
    local ++i
}
outreg, replay(diff)

* then summary statistics 
local count: word count $DESCVARS
mat sumstat = J(`count',6,.)

local i = 1
foreach var in $DESCVARS {
    quietly: summarize `var' if republicanjudge==0
    mat sumstat[`i',1] = r(N)
    mat sumstat[`i',2] = r(mean)
    mat sumstat[`i',3] = r(sd)
    quietly: summarize `var' if republicanjudge==1
    mat sumstat[`i',4] = r(N)
    mat sumstat[`i',5] = r(mean)
    mat sumstat[`i',6] = r(sd)
    local i = `i' + 1
}
frmttable, statmat(sumstat) store(sumstat) sfmt(g,f,f,g,f,f)

* Export 
outreg using "assignment4balance.tex", ///
    replay(sumstat) merge(diff) tex nocenter note("") fragment plain replace ///
    ctitles("", Control, "", "", Treatment, "", "", "" \ "", N, Mean, SD, N, Mean, SD, Diff) ///
    multicol(1,2,3;1,5,3) 


* From the balance table, we can see that there is a statistically insignificant difference between the severity of crime and whether the judge was a Republican or not. However, we can also see there there is a statistically significant difference between Republican vs. non-Republican judges when it comes to the months in jail and recidivates. Thus, it seems that judges, by political party, are randomly assigned on the basis of how severe the crime is. However, there's clearly a statistically significant difference in whether a criminal reoffends and how long of a sentence the criminal gets, depending on what judge s/he gets.*

* Question 5
* The first stage is to estimate predicted treatment. We would like to regress the nudge, in this case judge partisanship, on treatment, in this case, the number of months in jail.  

* X in this case would be the length of the prison ssentence, "monthsinjail"
* The outcome variable is recividism 
* The instrumental variable, z, is republicanjudge, since this variable is correlated with the main explantory variable of interest, length of prison sentence (republican judges give longer jail sentences, it seems). However, whether a judge is republican or not is also NOT correlated with other factors in the error term, such as poverty, etc. There's no logical way to connect the instrumental variable to the outcome variable, other than through months in jail. 


* run the first stage regression 
reg monthsinjail republicanjudge severityofcrime 
* Note, in this regression, we control for severity of crime, since it's not correlated with whether the judge is republican or not, as we saw from the balance test from before. However, it should be controlled because the length of time someone spends in jail is related to how severe the crime is. 
* Save and make Publication-quality table 
eststo Stage1
esttab Stage1 using Assignment4Table.tex, $tableoptions keep(republicanjudge severityofcrime _cons) star(* 0.10 ** 0.05 *** 0.01) collabels(none) stats(r2 N, fmt(%9.4f %9.0f %9.0fc) labels("R-squared" "Number of observations")) plain noabbrev nonumbers lines parentheses fragment


* Question 6: 
* From the regression, we can see that on average and holding severity of crime constant, having a republican judge will result on average in 3 more months of jail time, statistically significant to the 1% level. This means that republican judge is a good instrumental variable because it's related to our main X of interest, while not being correlated with unobserved error variables like poverty, etc. 

* Question 7: 
* Calculate "reduced form"
reg recidivates republicanjudge severityofcrime 

* Question 8 : create ratio 

reg recidivates republicanjudge severityofcrime 
mat beta = e(b)
svmat double beta, names(matcol)

reg monthsinjail republicanjudge severityofcrime 
mat beta1 = e(b)
svmat double beta1, names(matcol)

gen ratio = betarepublicanjudge / beta1republicanjudge 

* Question 9 
ivreg2 recidivates (monthsinjail=republicanjudge) severityofcrime
* Publication-quality table
eststo Stage2
esttab Stage2 using Assignment4Table1.tex, $tableoptions keep(monthsinjail severityofcrime _cons) star(* 0.10 ** 0.05 *** 0.01) collabels(none) stats(r2 N, fmt(%9.4f %9.0f %9.0fc) labels("R-squared" "Number of observations")) plain noabbrev nonumbers lines parentheses fragment

* Question 10 : F-stat is 164.34, which is greater than 10. So yes, it is above the conventional threshold. 

* Question 11 : Compare the ratio from 8 (.0442798) to coefficient on 9 (.0442798)
* The numberes are the same. They're both 0.0442798

* Question 12 
*In the research design above, using randomized judges, the always-takers are the criminals who will get long jail sentences, regardless of the judges' partisanship. 

*The never-takers are the criminals who will get short jail sentences, no matter the judges' partisanship. 

*The compliers are the criminals who will get long jail sentences if the judge is republican.  

*The defiers are the criminals who will long jail sentences if the judge isn't republican. 

*Question 13: 
* Monotonicity assumption is that there are no defiers. In the case of judges' partisanships and reoffenders, defiers would be the individuals who will get long jail sentences if the judge is not republican. If there are defiers in this case, that would be a problem, since the IV (in this case, the judges' partisanship) is only able to measure the causal effect of the treatment (jail time) for the compliers. 

* Question 14: 
* Compliers are people who will get long jail sentences if the judge is republican, but will get shorter jail sentences if the judge isn't. 

* Question 15: Yes, the cycle of crime hypothesis seems to be true for compliers (the only people that our IV is able to measure the causal effect of the treatment effect). As we can see, having a republican judge will make it about 4.4% more likely that the person will reoffend. Since the IV nudges compliers to the treatment (longer jail sentences), it seems that longer jail sentences will lead to an increased likelihood of recidivism, which is exactly what Obama was talking about. 

