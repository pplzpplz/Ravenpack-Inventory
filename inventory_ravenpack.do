cd "/Users/wangziang/Dropbox/blockchainBGT/data"
set more off

import delimited "/Users/wangziang/Library/CloudStorage/Dropbox/Shared_Wang_Ziang_TIAN/Blockchain/post_summary_20231013.csv", clear
duplicates drop gvkey fyear, force
gen blc_closecount = close_blockchain_post
gen blc_totalcount = close_blockchain_post + maybe_blockchain_post
gen blc_dummy=1 
replace blc_dummy = 0 if blc_closecount==0

use "/Users/wangziang/Library/CloudStorage/Dropbox/RA-Wenting/Compustat2000-2023/20002023.dta", clear
destring gvkey, replace
duplicates drop gvkey fyear, force
ren datadate compustat_datadate

merge m:1 gvkey fyear using hoberg_phillips
drop if _merge==2
drop _merge

merge m:1 gvkey fyear using ravenpack_blockchain
keep if _merge ==3
drop _merge

*Interactive Terms Upstreamness*
gen cusip6=substr(cusip,1,6)
ren fyear year
merge m:1 cusip6 year using "/Users/wangziang/Dropbox/ChenChong/Supplychain_Bank/Data/workingdata/up.dta"
drop if _merge==2
drop _merge

replace up = up+1
egen mean_up = mean(up)
replace up=mean_up if mi(up)

gen blc_dummy_up=blc_dummy*up
gen blc_closecount_up = blc_closecount*up
gen blc_totalcount_up = blc_totalcount*up

replace cogs =0 if cogs<0
gen lead_time = 365/(cogs/ap)
gen log_lead_time = log(lead_time+1)

gen invt_at = invt/at
gen log_at =log(at)
gen lev_at=(dlc+dltt)/at
gen rd_at = xrd/at
gen roa = sale/at

gen sic2=substr(sic,1,2)

tsset gvkey year
gen sales_growth=(f.sale-sale)/sale
gen delta_invt = (f.invt-invt)/invt
gen delta_leadtime = (f.lead_time - lead_time)/lead_time

local vars "invt_at log_at lev_at roa sales_growth rd_at tnic3hhi"
foreach var of local vars{
	bys sic2: egen mean_`var' = mean(`var')
	replace `var' = mean_`var' if mi(`var')
}

local vars "delta_invt delta_leadtime invt_at log_lead_time log_at lev_at roa sales_growth rd_at tnic3hhi"
winsor2 `vars', cuts(1 99) replace
winsor2 lead_time, cuts(10 90) replace

tsset gvkey year

rm lead_time.txt
rm inventory.txt
rm interaction.txt
rm placebo.txt

*Lead Time
reghdfe lead_time l.blc_dummy, absorb(gvkey year) vce(r)
outreg2 using lead_time.xls, append nolabel se dec(3)
reghdfe lead_time l.blc_dummy log_at lev_at roa sales_growth tnic3hhi, absorb(gvkey year) vce(r)
outreg2 using lead_time.xls, append nolabel se dec(3)
reghdfe lead_time l2.blc_dummy, absorb(gvkey year) vce(r)
outreg2 using lead_time.xls, append nolabel se dec(3)
reghdfe lead_time l2.blc_dummy log_at lev_at roa sales_growth tnic3hhi, absorb(gvkey year) vce(r)
outreg2 using lead_time.xls, append nolabel se dec(3)

*Inventory
reghdfe invt_at l.blc_dummy, absorb(gvkey year) vce(r)
outreg2 using inventory.xls, append nolabel se dec(3)
reghdfe invt_at l.blc_dummy log_at lev_at roa sales_growth tnic3hhi, absorb(gvkey year) vce(r)
outreg2 using inventory.xls, append nolabel se dec(3)
reghdfe invt_at l2.blc_dummy, absorb(gvkey year) vce(r)
outreg2 using inventory.xls, append nolabel se dec(3)
reghdfe invt_at l2.blc_dummy log_at lev_at roa sales_growth tnic3hhi, absorb(gvkey year) vce(r)
outreg2 using inventory.xls, append nolabel se dec(3)

* Interactive Terms
reghdfe invt_at l.blc_dummy up l.blc_dummy_up log_at lev_at roa sales_growth tnic3hhi, absorb(gvkey year) vce(r)
outreg2 using interaction.xls, append nolabel se dec(3)
reghdfe invt_at l2.blc_dummy up l2.blc_dummy_up log_at lev_at roa sales_growth tnic3hhi, absorb(gvkey year) vce(r)
outreg2 using interaction.xls, append nolabel se dec(3)
reghdfe lead_time l.blc_dummy up l.blc_dummy_up log_at lev_at roa sales_growth tnic3hhi, absorb(gvkey year) vce(r)
outreg2 using interaction.xls, append nolabel se dec(3)
reghdfe lead_time l2.blc_dummy up l2.blc_dummy_up log_at lev_at roa sales_growth tnic3hhi, absorb(gvkey year) vce(r)
outreg2 using interaction.xls, append nolabel se dec(3)

* Placebo
reghdfe lead_time f.blc_dummy log_at lev_at roa sales_growth tnic3hhi, absorb(gvkey year) vce(r)
outreg2 using placebo.xls, append nolabel se dec(3)
reghdfe lead_time blc_dummy log_at lev_at roa sales_growth tnic3hhi, absorb(gvkey year) vce(r)
outreg2 using placebo.xls, append nolabel se dec(3)
reghdfe invt_at f.blc_dummy log_at lev_at roa sales_growth tnic3hhi, absorb(gvkey year) vce(r)
outreg2 using placebo.xls, append nolabel se dec(3)
reghdfe invt_at blc_dummy log_at lev_at roa sales_growth tnic3hhi, absorb(gvkey year) vce(r)
outreg2 using placebo.xls, append nolabel se dec(3)


*Summary Statistics
tabstat blc_dummy invt_at lead_time up log_at lev_at roa sales_growth rd_at tnic3hhi, columns(statistics) stat(mean sd min p25 p75 max)

use ravenpack_blockchain, clear
bys fyear: egen tot_blc_closecount = total(blc_closecount)
bys fyear: egen tot_blc_totalcount = total(blc_totalcount)






















