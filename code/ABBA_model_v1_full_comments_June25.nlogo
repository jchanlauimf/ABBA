;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  ABBA_model_v1.netlogo
;;  Jorge A. Chan-Lau
;;  International Monetary Fund
;;  jchanlau@imf.org
;;
;;  December 2014
;;
;;  Version 1
;;
;;  This program implements the ABBA model described in:
;;
;;  Chan-Lau, Jorge A., 2014, Bank Solvency, Liquidity, Profitability and 
;;  Interconnectedness: Insights from Agent-Based Model Simulations
;;
;;  Please refer to the above mentioned paper for details on the logic and equations
;;  underlying the model
;;
;;  Please do not circulate without authorization
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


extensions [table matrix]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals [
  
  ;; ----------------
  ;; world parameters
  ;; ----------------
  
  xmax           ;; determines x-axis boundaries in world
  xmin           ;; determines x-axis boundaries in world
  ymax           ;; determines y-axis boundaries in world
  ymin           ;; determines y-axis boundaries in world
  n-banks        ;; initial number of banks operating in world
  table-sector   ;; saves x and y coordinates of each bank sector
  sector         ;; auxiliary variable, used to create the neighborhoods  
  inner-radius   ;; places the banks within the circular world
  outer-radius   ;; outer boundary of the circular world


  ;;------------------------
  ;; interest rates
  ;;

  Libor-rate     ;; interbank lending/borrowing rate        
  rfree          ;; risk-free rate, used to determine lending rates
  reserve-rates  ;; interest rate paid on bank-reserves
  
  ;;------------------------
  ;; regulatory requirements
  ;;
    
  min-reserves-ratio  ;; minimum reserves ratio requirement
  CAR                 ;; capital adequacy ratio requirement
  

  ;;------------------------
  ;; bank-specific variables
  ;;

  initial-equity        ;; initial equity at beginning of simulation
  bankrupt-liquidation  ;; determines liquidation values of loans
                        ;; when winding down banks

  
  ;; ------------------
  ;; Control parameters
  ;;
  
  n-loans        ;; number of potential loans (firms) available to banks
  n-savers       ;; number of potential savers (depositors) 
  n-ticks        ;; maximum number of ticks (periods) to run the program


  ;; ------------------------------------------
  ;; auxiliary variables for debugging purposes
  ;;
  
  agentset1
  agentset2
  agentset3
   
  
  ;; ------------------------------------------
  ;; Simulation controls
  ;; 
  idx-simulations
  n-simulations
  
]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Types of agents

breed [dalis dali]     ;; use to draw the boundaries of the circular world


breed [loans loan]
breed [banks bank]
breed [savers saver]
directed-link-breed [IBloans IBloan]

patches-own [
  patch-region-id
]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Agents' characteristics
;;



;;--------------------
;; Savers (depositors)
;;

savers-own[
  balance            ;; deposit balance with bank
  withdraw-prob      ;; probability of withdrawing deposit and shift to other bank
  exit-prob          ;; probability that saver withdraws and exits banking system
  bank-id            ;; identity of saver's bank 
  region-id          ;; regionof saver
  owns-account?      ;; owns account with bank-id
  saver-solvent?     ;; solvent if bank returns principal 
                     ;; may become insolvent if bank is bankrupt
  saver-exit?        ;; saver exits the banking system?
  saver-current?     ;; old saver/ if false, it is a new entrant to the system
  
  saver-last-color   ;; used to create visual effects
]

;;--------------------
;; Interbank loans
;;

IBloans-own[
  IB-rate            ;; interbank loan rate
  IB-amount          ;; interbank amount
  IB-last-color      ;; used to create visual effects  
]

;;---------------------
;; Loan characteristics
;;

loans-own [
  
  
  ;; Loan intrinsic characteristics
  ;;

  pdef               ;; true probability of default
  amount             ;; amount of loan - set to unity
  rweight            ;; true risk-weight of the loan 
  rwamount           ;; amount * rweight
  lgdamount          ;; loss given default (1-rcvry-rate) * amount
  loan-recovery      ;; rcvry-rate * amount
  rcvry-rate         ;; recovery rate in case of default
  fire-sale-loss     ;; loss percent if sold or removed from bank book
  rating             ;; loan rating - we can specify the rating and then assign
                     ;; pdef from a table - not used
  region-id          ;; Identity of loan's neighborhood - useful for analyzing 
                     ;; cross-country/ regional lending patterns
  
  ;; Loan status

  loan-approved?     ;; is loan loan-approved? 
  loan-solvent?      ;; is loan solvent?
  loan-dumped?       ;; loan dumped during risk-weighted-optimization
  loan-liquidated?   ;; loan liquidated owing to bank-bankruptcy
  bank-id            ;; identity of lending bank
  
  ;; Loan pricing 
  ;;

  rate-quote         ;; rate quoted by lending bank
  rate-reservation   ;; maximum rate borrower is willing to pay [not used here]
  loan-plus-rate     ;; amount * (1 + rate-quote)
  interest-payment   ;; amount * rate-quote
  
  ;; Auxiliary variables
  
  loan-last-color    ;; used to create visual effects
    
  
]

;;---------------------
;; Bank characteristics
;;

banks-own [
  

  ;; Balance-sheet components
  ;;

  equity                  ;; equity (capital) of the bank  
  bank-deposits           ;; deposits raised by bank
  bank-loans              ;; amount total loans made by bank
  bank-reserves           ;; liquid bank-reserves
  total-assets            ;; bank-loans + bank-reserves
  
  ;; Bank buffers
  
  bank-provisions         ;; provisions against expected losses
  bank-new-provisions     ;; required provisions, not met if bank defaults
  
  ;; Prices
  
  rdeposits               ;; deposit rate

  ;; interbank loan holdings
  ;;
  
  IB-credits              ;; interbank loans to other banks
  IB-debits               ;; interbank loans from other banks

  ;; Income components
  ;;
  
  net-interest-income     ;; net interest income, balance sheet
  interest-income         ;; interest income, loans
  interest-expense        ;; interest expense, depositors
  IB-interest-income      ;; interest income, interbank
  IB-interest-expense     ;; interest expense, interbank
  IB-net-interest-income  ;; net interest, interbank
  IB-credit-loss          ;; credit losses, interbank exposures

  ;; reporting requirements
  ;;

  capital-ratio           ;; capital to risk-weighted assets
  reserves-ratio          ;; reserves to deposits
  rwassets                ;; risk-weighted assets  
  leverage-ratio          ;; leverage ratio = equity / total-assets
  
  
  bank-dividend           ;; dividends                       
  bank-cum-dividend       ;; cumulative dividends

  
  ;; Bank ratios
  ;; 
  
  
  upper-bound-cratio      ;; upper-bound of capital ratio
                          ;; if capital ratio exceeds
                          ;; upper-bound excess cpital 
                          ;; pay as dividend
                       
  buffer-reserves-ratio   ;; desired buffer or markup over
                          ;; minimum-reserves-ratio
                       
  ;; random changes to deposit levels
  
  deposit-outflow         ;; deposit withdrawal shock
  deposit-inflow          ;; deposit inflow from other banks
  net-deposit-flow        ;; net deposit flow

  
  bank-solvent?           ;; bank solvent?
  bank-capitalized?       ;; bank capitalized?
  defaulted-loans         ;; amount of defaulted loans
  
  credit-failure?         ;; credit failure
  liquidity-failure?      ;; liquidity failure
  assets=liabilities?     ;; control variable
     
  ;; other variables of interest - to be added later
  ; average-risk-of-loans  - set equal to average PD
  ; average-recovery-of-loans
  ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;--------------------------------------------------------------------------------------
;; SETUP procedure
;;
;; Creates spatial world where the banks operates and initializes the different set
;; of agents: banks, loans, savers, and interbank links
;;
;;--------------------------------------------------------------------------------------


to setup
  clear-all
  setup-global      ;; initialized global variables
  setup-world       ;; setup circular world, assigning neighborhoods to banks
  setup-banks
  setup-loans       ;; populate world with potential loans
  setup-loan-id     ;; set bank-id and region-id
  setup-depositors  ;; populate world with depositors  
  setup-IB-loans    ;; set interbank links - currently shapes only
  reset-ticks
end

to main-run-program-recursive
  
  clear-all
  
  show "running ..."
 
  ifelse (file-exists? "interbank-exposure.csv") [
    file-delete "interbank-exposure.csv"]
  [ file-open "interbank-exposure.csv"]
  
  ifelse (file-exists? "bank-ratios.csv") [
    file-delete "bank-ratios.csv"]
  [ file-open "bank-ratios.csv"]
      
;;  let list-CAR [0.04 0.08 0.12 0.16]
;;  let list-reserves-ratio [0.03 0.045 0.06]

  let list-CAR [0.08]
  let list-reserves-ratio [0.03];
  
  set n-simulations 10
  set idx-simulations 1
  
  while [idx-simulations <= n-simulations] [
  
    let iCAR 0
    while [iCAR < length list-CAR] [
        
      set CAR item iCAR list-CAR
      
      let iResRatio 0
      while [iResRatio < length list-reserves-ratio] [
     
        clear-turtles
        clear-links
        clear-output  
        clear-ticks
       
        set min-reserves-ratio item iResRatio list-reserves-ratio
        
        type "Simulation:" type idx-simulations
        type " CAR: " type CAR
        type " reserves-ratio: " type min-reserves-ratio
        print " "

             
        setup-global      ;; initialized global variables
        setup-world       ;; setup circular world, assigning neighborhoods to banks
        setup-banks
        setup-loans       ;; populate world with potential loans
        setup-loan-id     ;; set bank-id and region-id
        setup-depositors  ;; populate world with depositors  
        setup-IB-loans    ;; set interbank links - currently shapes only
        initialize-deposit-base
        initialize-loan-book
        
        reset-ticks
        
        let i 0
        let any-bank-solvent? true
        set n-ticks 300
        while [i < n-ticks and any-bank-solvent?] [
          
          ;; evaluate solvency of banks after loans experience default
          ;; 
          main-evaluate-solvency 
          
          ;; evaluate second round effects owing to cross-bank linkages
          ;;   only interbank loans to cover shortages in reserves requirements
          ;;   are included
          ;;
          main-second-round-effects
         
          ;; Undercapitalized banks undertake risk-weight optimization
          ;; 
          main-risk-weight-optimization
            
          ;; banks that are well capitalized pay dividends
  
          main-pay-dividends
          
          ;; Reset insolvent loans, i.e. rebirth lending opportunity
          ;;   
          main-reset-insolvent-loans
          
          ;; Build up loan book with loans available in bank neighborhood
          ;;  
            
          main-build-loan-book-locally
      
          ;; Build up loan book with loans available in other neighborhoods
          ;;     
          main-build-loan-book-globally
      
          
          ;; main-raise-deposits-build-loan-book 
      
      
               
          ;; Evaluate liquidity needs related to reserves requirements
          ;;
          main-evaluate-liquidity
          
          ;; Write main results of the model
          
          main-write-interbank-links
          main-write-bank-ratios
          
          ;; 
          
          
          set any-bank-solvent? any? banks with [bank-solvent?]    
          set i i + 1    
          tick
        ]
        set iResRAtio iResRatio + 1
      ]
      set iCAR iCAR + 1
    ]
    set idx-simulations idx-simulations + 1
  ]
  
  
  file-open "interbank-exposure.csv"
  file-close 
  file-open "bank-ratios.csv"
  file-close
  file-open "bank-ratios-clean.csv"
  file-close
  
  show "finished"
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   
;; SETUP PROCEDURES BLOCK
;;
;;   setup-global
;;   setup-world
;;   setup-loans
;;   setup-loan-id
;;   setup-depositors
;;   setup-IB-loans
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to setup-global
  set xmax 400
  set ymax 400
  set xmin -400
  set ymin -400
  set n-banks 10
  set inner-radius 0.6 * xmax
  set outer-radius 0.8 * xmax
  set table-sector table:make
  
  set initial-equity 100
  set n-loans 20000
  set n-savers 10000  
  set rfree 0.01
  set reserve-rates rfree / 2  ; set reserve-rates one half of risk-free rate
  set Libor-rate rfree
  set bankrupt-liquidation 1   ; set to 0 if bank liquidates loans at face value
                               ; set to 1 if it is fire-sale of assets
                                 
end

to setup-world
  
  ;;------------------------
  ;; Create circular regions
  ;;
  
;;  clear-all  
  setup-global
  create-banks n-banks
  resize-world xmin xmax ymin ymax
  set-patch-size 1
  ask patches [
    set patch-region-id 9999
  ]
  
  ;;-------------------------------------------------------------------------
  ;;
  ;; Create banks and set their bank attributes
  ;;

  ;;-------------------------------------------------------------------------
  ;; Draw radius and circumference, showing neighborhood boundaries
  ;;  
  
  subroutine-draw-sectors

end

to setup-banks  

;;  create-banks n-banks
   
  ask banks [ 
    
    ;;-----------------------------------------------------------------------
    ;; Assign values to bank  attributes
    ;;

    set equity initial-equity          ;; identical banks
    set bank-reserves 0
    set bank-deposits 0
    set bank-provisions 0
    set rdeposits rfree                ;; assumes deposits are risk free
    set bank-solvent? true             ;; all banks initially solvent
    set defaulted-loans 0              ;; defaulted loans
    set bank-capitalized? true         ;; all banks initially capitalized
    set bank-dividend 0
    set bank-cum-dividend 0 
    set upper-bound-cratio 1.5 * CAR   ;; set upper bound for capital ratio
                                       ;; set it to large number, i.e. 100 if
                                       ;; if unbounded
    set buffer-reserves-ratio 1.5 
    set credit-failure? false
    set liquidity-failure? false
    set IB-credits 0
    set IB-debits 0                                   
    
    ;;-----------------------------------------------------------------------
    ;; Graphical shapes of banks 
    ;;    

    set shape "circle" 
    set color green
    set size 20
    set label who
    
    ] ;; end ask banks


  ;;-------------------------------------------------------------------------
  ;;
  ;; Place banks in the circular world
  ;;  

  let theta  360 / n-banks

  let i 0
  while [i < n-banks][
    let itheta (2 * i + 1) * theta / 2    
    ask turtle i[  
      setxy inner-radius * cos (itheta) inner-radius * sin (itheta)]
    set i  i + 1
  ]
  
  
  ;;-------------------------------------------------------------------------
  ;; Create table mapping patches with specific circular sectors
  ;; Note: old procedure, can be simplified
  ;;

  set i 0  
  while [i < n-banks]
  [
    let angle0 90 - i * theta
    let angle1 90 - (i + 1) * theta
    if angle0 < 0 [set angle0 360 + angle0] 
    if angle1 < 0 [set angle1 360 + angle1]
    let dif-angle abs (angle1 - angle0)    

    ifelse dif-angle = theta 
    [ set sector [list pxcor pycor ] of patches with 
      [
        pxcor ^ 2 + pycor ^ 2 <= outer-radius ^ 2 and
        abs(pxcor)  + abs(pycor) > 0 and
        atan pxcor pycor < angle0 and 
        atan pxcor pycor >= angle1
        ]
      
      ask patches with 
       [
        pxcor ^ 2 + pycor ^ 2 <= outer-radius ^ 2 and
        abs(pxcor)  + abs(pycor) > 0 and
        atan pxcor pycor < angle0 and 
        atan pxcor pycor >= angle1
        ]
       [ set patch-region-id i]
       

    ]
    [ set sector [list pxcor pycor] of patches with
      [
        pxcor ^ 2 + pycor ^ 2 <= outer-radius ^ 2 and
        abs(pxcor)  + abs(pycor) > 0 and
        (atan pxcor pycor < angle0 and atan pxcor pycor >= 0
        or atan pxcor pycor >= angle1)
        ]      

      ask patches with 
       [
        pxcor ^ 2 + pycor ^ 2 <= outer-radius ^ 2 and
        abs(pxcor)  + abs(pycor) > 0 and
        (atan pxcor pycor < angle0 and atan pxcor pycor >= 0
        or atan pxcor pycor >= angle1)
        ]
       [ set patch-region-id i]
      
      ]       
    let idx i
    table:put table-sector idx sector    
    set i i + 1         
  ]

 

end

to subroutine-draw-sectors
  
    let theta  360 / n-banks
   
    create-dalis 1      
    let i 0
    
    ;; draw radiuses
    while [i < n-banks] [
        let angle0 i * theta
        let angle1 (i + 1) * theta
        ask dalis [
          set color white
          pen-down
          setxy 0 0
          setxy outer-radius * cos(angle0) outer-radius *(sin angle0) 
          setxy 0 0]
        set i i + 1
    ]
    
    ;; draw circumference
    set i 0
    while [i <= 360]
    [
    ask dalis [
      set color white
      pen-down 
      setxy outer-radius * cos(i) outer-radius * sin(i)]
    set i i + 0.25
    ]
    ask dalis [die]

end


to setup-loans
  
  ask patch 399 399 [sprout-loans n-loans]
;;   create-loans n-loans

  let circle-world patches with [pxcor ^ 2 + pycor ^ 2 <= outer-radius ^ 2]
  
  ask loans [
;    set color yellow
;    pen-down
    move-to one-of circle-world    
    let location-id 0
    ask patch-here [
      set location-id patch-region-id]
    set bank-id location-id  
  ]

; following line no longer needed
;  ask loans with [ xcor ^ 2 + ycor ^ 2 > outer-radius ^ 2][ die]  
;  ask loans [setxy random-xcor random-ycor]
  ask loans [ 
    set color black
    set shape "house"
    set size 1]

  ask loans [set color 107]
  ask loans [
    set amount 1
    set loan-solvent? true
    set loan-approved? false    
    set loan-dumped? false
    set loan-liquidated? false
    set pdef assign-random-pd-rule
    set rweight assign-linear-rweight pdef
    set rcvry-rate assign-constant-recovery-rate
    set rate-quote assign-pd-sensitive-rate pdef rfree rcvry-rate
    set lgdamount (1 - rcvry-rate) * amount
    set loan-recovery rcvry-rate * amount
    set loan-plus-rate (1 + rate-quote) * amount
    set interest-payment rate-quote * amount
    set rwamount rweight * amount

    ;; fire-sale-loss  percent of value lost when selling loan
    ;; varies random between 0 and 10 percent
    ;; if it is too high nobody rebalances 
    
    set fire-sale-loss random 11 
    set fire-sale-loss fire-sale-loss / 100
  ]
end

to setup-depositors
  
  ask patch 399 399 [sprout-savers n-savers]
  
  let circle-world patches with [pxcor ^ 2 + pycor ^ 2 <= outer-radius ^ 2]
  
  ask savers [
;    set color yellow
;    pen-down
    move-to one-of circle-world    
    let location-id 0
    ask patch-here [
      set location-id patch-region-id]
    set bank-id location-id  
  ]

  ask savers [
;    setxy random-xcor random-ycor
    set balance 1
    set owns-account? false
    set saver-solvent? true
    set withdraw-prob random 21
    set withdraw-prob withdraw-prob / 100
    set exit-prob random 6
    set exit-prob exit-prob / 100
    set saver-exit? false
    set color black
    set shape "person"    
    set size 1    
  ]
  ask savers with [ xcor ^ 2 + ycor ^ 2 > outer-radius ^ 2] [die]  
  ask savers [ set color 25]
end

to setup-loan-id
    let i 0
    while [i < n-banks ] [
      set sector subroutine-find-hood i
      let loans-here loans at-points sector
      
      ; Initially set region-id and bank-id equally
      ; so at the beginning, only bank with bank-id 
      ; has rights over these loans, i.e. monopoly power
      ; once the bank is undercapitalized or bankrupt,
      ; other banks can claim the loan
      ; bank-id will change but region-id remain the same
      
      ask loans-here [ set bank-id i]  
      ask loans-here [ set region-id i]
      set i i + 1
    ]

end

to setup-IB-loans
  set-default-shape IBloans "curved link"
  ask ibloans [set thickness 10]

  
  ;; color set to black to keep them 
  ;; invisible until debits and credits
  ;; are incurred
  
;  ask banks [
;    create-IBloans-to other banks [
;      set color black]   
;  ]
  
;  ask IBloans [
;    set IB-rate Libor-rate
;    set IB-amount 0
;  ]
end

;;-------------------
;; Reporters routines
;;-------------------


to-report assign-random-pd-rule
  let probd random 10
  set probd probd + 1
  set probd probd / 100
  report probd
end

to-report assign-linear-rweight[this-pd]
  let rw 0.5 + this-pd * 5
  report rw
end

to-report assign-constant-lending-rate
  let lending-rate  0.06
  report lending-rate
end

to-report assign-constant-recovery-rate
  let recovery-rate 0.40
  report recovery-rate
end

to-report assign-pd-sensitive-rate [this-pd this-rfree this-rr]
  let lending-rate (1 + this-rfree) - this-rr *  this-pd
  set lending-rate lending-rate / (1 - this-pd) - 1  
  report lending-rate * 1.2
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; END SETUP PROCEDURES BLOCK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   
;; BEHAVIORAL PROCEDURES BLOCK
;; 
;; Main procedures
;;
;;   initialize-deposit-base           Ask banks to raise deposits 
;;   initialize-loan-book             Build banks' initial loan books
;;   main-evaluate-solvency           Calculate bank solvency
;;   calculate-credit-loss            Assesses credit losses
;;   calculate-liquidity-need         Measures liquidity needs
;;   rebalance-credit                 rebalance balance-sheet to meet CAR
;;   rebalance-liquidity              rebalance balance-sheet to meet reserves
;;
;; Auxiliary procedures
;;   subroutine-find-hood            
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::::::


;; --------------- ;;
;; Main procedures ;;
;; --------------- ;;


;; initialize-deposit-base
;;
;; Notice that after raising deposits, the asset side of the balance sheet
;; of the bank has not been constructed yet so assets do not match liabilities
;;
;; Notice that all savers in the region own accounts with the local bank,
;; this may lead to excessive deposits and high reserve ratios
;; Potential solutions include
;;   include procedure for banks to reduce deposits to meet internal reserve ratios
;;   or increase the number of loans relative to deposits to force banks to hold
;;   a thin deposit layer



to initialize-deposit-base
  let i 0
  while [i < n-banks][
    set sector subroutine-find-hood i   
    ask savers at-points sector [
      set bank-id i
      set owns-account? true]
    let sum-deposits sum [balance] of savers at-points sector
    ask bank i [ 
      set bank-deposits sum-deposits
      set bank-reserves bank-deposits + equity
      ]    
;;    ask bank i [ set bank-reserves round (bank-deposits * min-reserves-ratio)]
    set i i + 1
  ]
end


;; Examine the banks after running construct-loan-book-random
;; asset and liabilities should match well
;; equity + deposits = reserves + loans
;; not-being used now

to initialize-loan-book
  
  ask banks [

    let bank-number who
    let loans-here loans with [bank-id = bank-number]

    
    set bank-reserves equity + bank-deposits 
    set reserves-ratio bank-reserves / bank-deposits
    let max-rwa equity / (1.1 * CAR)
    
    let interim-reserves bank-reserves
    let interim-deposits bank-deposits
    let interim-reserves-ratio reserves-ratio
    let rwa 0
    let unit-loan 0
    let available-loans? true
    
    while [ available-loans? and rwa < max-rwa and 
      interim-reserves-ratio > buffer-reserves-ratio * min-reserves-ratio]  [
      
      let pool-loans loans-here with [loan-approved? = false]

      set available-loans? any? pool-loans
            
      if available-loans? [     
        ask one-of pool-loans [
          
          set interim-reserves interim-reserves - amount 
          set interim-reserves-ratio interim-reserves / interim-deposits 
          set loan-approved? true 
          set unit-loan unit-loan + amount
          set rwa rwa + rweight * amount
          set color yellow
        ]
      ]
    ]
    
    set bank-loans unit-loan
    set rwassets rwa
    set bank-reserves bank-deposits + equity - bank-loans
    set reserves-ratio bank-reserves / bank-deposits
    set capital-ratio equity / rwassets
    set bank-provisions sum [pdef * lgdamount] of loans with 
     [ bank-id = bank-number and loan-approved? and loan-solvent?]
    set bank-solvent? true  
    set total-assets bank-loans + bank-reserves
    set leverage-ratio equity / total-assets
  ]

end

to main-evaluate-solvency 
  
  let solvent-banks banks with [bank-solvent?]
  
  ask solvent-banks [

    let bank-number who
    
    calculate-credit-loss-loan-book bank-number   
    calculate-interest-income-loans bank-number
    calculate-interest-expense-deposits bank-number
    calculate-net-interest-income bank-number

    set equity equity + net-interest-income
    set capital-ratio equity / rwassets
    
    set bank-reserves bank-reserves + net-interest-income
    set reserves-ratio bank-reserves / bank-deposits
    
    if equity < 0 [ 
      set bank-solvent? false 
      set bank-capitalized? false
      set credit-failure? true
      set color red
      process-unwind-loans-insolvent-bank bank-number bankrupt-liquidation
      ]
    if (capital-ratio < CAR and capital-ratio > 0)[        
      set bank-capitalized? false
      set bank-solvent? true
      set color cyan
      set capital-ratio equity / rwassets
      set reserves-ratio bank-reserves / bank-deposits
      set total-assets bank-loans + bank-reserves
      set leverage-ratio equity / total-assets
      ]  
    if (capital-ratio > CAR) [
      set bank-capitalized? true
      set bank-solvent? true
      set color green
      set capital-ratio equity / rwassets
      set reserves-ratio bank-reserves / bank-deposits
      set total-assets bank-loans + bank-reserves
      set leverage-ratio equity / total-assets

      ]
    
  ]
  
end

to calculate-credit-loss-loan-book [i]

    let loans-with-bank loans with [bank-id = i and loan-approved? and loan-solvent?]

    ask loans-with-bank [
      let default-shock random 101
      set default-shock default-shock / 100
      if pdef > default-shock [
        set loan-solvent? false
        set color magenta
        ]
      set rwamount rweight * amount
    ]

    let loans-with-bank-default loans-with-bank with [not loan-solvent?]    

    ask bank i [
      
      ;; notice that deposits do not change when loans are defaulting
      
      set rwassets rwassets - sum [rwamount] of loans-with-bank-default
       
      ;; Add provisiosn to equity to obtain the total buffer against credit losses, 
      ;; substract losses, and calculate the equity amount before new provisions
         
      set equity equity - sum [lgdamount] of loans-with-bank-default
 
      ;; Calculate the new required level of provisions and substract of equity
      ;; equity may be negative but do not set the bank to default yet until 
      ;; net income is calculated
      ;; 
      ;; Notice that banks with negative equity are not allowed to optimize risk-weights
      ;; - in principle, reducing the loan book could release provisions and make the bank
      ;;   solvent again
      
 
      set bank-new-provisions sum [pdef * lgdamount] of loans with [bank-id = i and
         loan-approved? and loan-solvent?]
      
      let change-in-provisions bank-new-provisions - bank-provisions
      
      set bank-provisions bank-new-provisions
      set equity equity - change-in-provisions
      set bank-reserves bank-reserves + sum [loan-recovery] of loans-with-bank-default
      set bank-reserves bank-reserves - change-in-provisions
      set bank-loans bank-loans - sum [amount] of loans-with-bank-default
      set defaulted-loans defaulted-loans + sum [amount] of loans-with-bank-default 
      set total-assets bank-reserves + bank-loans
      
    ]
end


to process-unwind-loans-insolvent-bank [bank-number choice-number]
  
  ;; Remember bank enters with negative equity after posting the required provisions
  ;; so the money available from provisions is:
  ;;
  ;; bank-provisions + equity (the latter is negative)
  ;;
    
  
  let loans-with-insolvent-bank loans with 
      [ bank-id = bank-number and
        loan-approved? and loan-solvent? ]
    
  let savers-with-insolvent-bank savers with 
      [ bank-id = bank-number and owns-account? ]
  
  ask savers-with-insolvent-bank [set owns-account? false]
  
  ;; Two possible options when bank is insolvent:
  ;; 0. loans become insolvent, bank recovers recovery from loans
  
  ;; is lgdamount the right amount? 
  ;; perhaps it should be rcvry-amount
  
  ;; original lines below
  
  ;;  let proceeds-from-liquidated-loans sum [ lgdamount] of
  ;;    loans-with-insolvent-bank
  
    let proceeds-from-liquidated-loans sum [loan-recovery] of
      loans-with-insolvent-bank
  
  ;; 1. loans are sold in the market, and banks suffer fire-sale losses
 
  let proceeds-from-sold-loans sum [ (1 - fire-sale-loss) * amount] of 
      loans-with-insolvent-bank
    
  let proceeds-from-loans 0   
  if choice-number = 0 [set proceeds-from-loans proceeds-from-liquidated-loans]
  if choice-number = 1 [set proceeds-from-loans proceeds-from-sold-loans]
     
  ;; Notice in this calculation that bank-provisions + equity < bank-provisions
  ;; since equity is negative for banks forced to unwind loan portfolio
     
  let recovered-funds 0
  ask bank bank-number [ 
    set recovered-funds bank-reserves + proceeds-from-loans + bank-provisions + equity       
    set recovered-funds round (recovered-funds)
    ]
  
  ;; Note that when bank is illiquid, recovered-funds may be negative
  ;; in this case, the bank cannot pay any of the savers   
  
  if (recovered-funds < 0 ) [
    ask savers-with-insolvent-bank [
      set saver-solvent? false
      set balance 0
      set color brown
    ]    
  ]
  
  if (recovered-funds < count savers-with-insolvent-bank
    and recovered-funds > 0 ) [
    
    let insolvent-savers count savers-with-insolvent-bank - recovered-funds   
    
    ask n-of insolvent-savers savers-with-insolvent-bank [ 
         set saver-solvent? false
         set balance 0    
         set color brown
    ]
  ]

  ask loans-with-insolvent-bank [
    set bank-id 9999
    set loan-approved? false
    set loan-solvent?  false
    set loan-liquidated? true
    set color turquoise
  ]
  
  
  ask bank bank-number [
    
    ;; they should add to zero 
    
    set bank-loans sum [amount] of loans with [
      bank-id = bank-number and 
      loan-approved? and 
      loan-solvent?]
    
    ;; they should add to zero 0 

    set bank-deposits sum [balance] of savers with [
      bank-id = bank-number and
      owns-account? ]
    
    set equity 0
    set bank-reserves 0
    set reserves-ratio 0
    set leverage-ratio 0
    set rwassets 0
    set bank-solvent? false
    set bank-capitalized? false
    set total-assets 0
    set capital-ratio 0
    set color red
   
  ]
 
end


to calculate-interest-income-loans [i]
    let loans-with-bank loans with [bank-id = i and loan-approved? and loan-solvent?]
    ask bank i [
      set interest-income sum [interest-payment] of loans-with-bank
      set interest-income interest-income + (bank-reserves + bank-provisions) * reserve-rates
    ]
    
end

to calculate-interest-expense-deposits [i]
    let deposits-with-bank savers with [bank-id = i]
    ask bank i[
      set interest-expense sum [balance] of deposits-with-bank
      set interest-expense interest-expense * rdeposits
    ]
end

to calculate-net-interest-income [i]
    ask bank i [
      set net-interest-income interest-income - interest-expense
    ]
end

to main-second-round-effects 
  
  ;; review this section - why solvent-banks have capital-ratio > = CAR
  ;; because interbank loans are only issued to banks with capital-ratios
  ;; above CAR
  
;  let solvent-banks banks with [capital-ratio >= CAR]
;  let insolvent-banks banks with [capital-ratio < CAR]

  let solvent-banks banks with [bank-solvent?]
  let insolvent-banks banks with [not bank-solvent?]
  let solvent-banks-afterwards []

  while [ solvent-banks != solvent-banks-afterwards] 
  [
  
    ask solvent-banks[
      let bank-number who
      
      ;; ----------------------------------------------------------------------
      ;; Interbank market gains and losses
      ;; A different block is needed if other interbank exposures are used
      ;;
      
      calculate-interbank-credit-loss bank-number
      calculate-interbank-interest-income bank-number
      calculate-interbank-interest-expense bank-number
      calculate-interbank-net-interest-income bank-number
      
      let principal-only 0
      let interest-only 0
      let my-ibloans []
      
      ifelse IB-net-interest-income > 0  ; bank is a creditor in the interbank market
        ;; check if principal should be paid or not.
        [
          set my-ibloans my-out-ibloans
          set principal-only sum [ib-amount] of my-ibloans
          set interest-only sum [ib-amount * ib-rate] of my-ibloans         
          set equity equity + interest-only - IB-credit-loss
          set bank-reserves bank-reserves + principal-only 
            + interest-only - IB-credit-loss
        ]
        ;; if the bank is a debtor, the bank has to repay the loans to other banks
        ;; hence, principal and interests are paid.
        [
          set my-ibloans my-in-ibloans
          set principal-only sum [ib-amount] of my-ibloans
          set interest-only sum [ib-amount * ib-rate] of my-ibloans
          set equity equity - interest-only
          set bank-reserves bank-reserves - principal-only - interest-only          
        ]
      
      
      ;; -----------------------------------------------------------------------

      set total-assets bank-reserves + bank-loans
      set leverage-ratio equity / total-assets
  
      set capital-ratio equity / rwassets
      set reserves-ratio bank-reserves / bank-deposits
            
      if ( equity < 0 or bank-reserves < 0) [ 
        set bank-solvent? false 
        set bank-capitalized? false
        set color red
        
        ;; assumes interbank loans are unsecured and not paid
        
        process-unwind-loans-insolvent-bank bank-number bankrupt-liquidation
        ]
      if (capital-ratio < CAR and capital-ratio > 0)[        
        set bank-capitalized? false
        set bank-solvent? true        
        set color cyan
        set capital-ratio equity / rwassets
        set reserves-ratio bank-reserves / bank-deposits
        set total-assets bank-loans + bank-reserves
        set leverage-ratio equity / total-assets
        
        ] 
      if (capital-ratio > CAR)[        
        set bank-capitalized? true
        set bank-solvent? true
        set color green
        set capital-ratio equity / rwassets
        set reserves-ratio bank-reserves / bank-deposits
        set total-assets bank-loans + bank-reserves
        set leverage-ratio equity / total-assets
        ]      
    ]
    
    ;; check the new set of solvent-banks
    
;    set solvent-banks-afterwards banks with [capital-ratio >= CAR]
    set solvent-banks-afterwards banks with [bank-solvent?]
    if (solvent-banks != solvent-banks-afterwards)[
      let temp-agentset solvent-banks-afterwards
      set solvent-banks-afterwards []
      set solvent-banks temp-agentset
    ]
  ]
  
  ;; The IB-credits and debits are cleared after banks recovered them
  ;; from solvent banks or charge them off in case of losses
  ;; Balance sheet components have already factored in their impact on 
  
  
  ask banks [
    set IB-credits 0
    set IB-debits 0
    set IB-interest-income 0
    set IB-interest-expense 0
    set IB-net-interest-income 0
    set IB-credit-loss 0
    
  ]
  
  ask links [die]
  
  
end     


to calculate-interbank-credit-loss [bank-number]
  let credit-loss-counterpart 0
  ask bank bank-number[
    let defaulted-loan 0
    let counterparty-debtor out-IBloan-neighbors
    let insolvent-counterparties counterparty-debtor with [not bank-solvent?]
    ask insolvent-counterparties [
        ask in-IBloan-from bank bank-number [
          set defaulted-loan IB-amount
          set credit-loss-counterpart credit-loss-counterpart + defaulted-loan
          ]
      ]
    set IB-credit-loss credit-loss-counterpart
    ] 
end

to calculate-interbank-interest-income [bank-number]
  let interbank-interests 0
  ask bank bank-number[
    let bank-interest-payment 0
    let counterparty-debtor out-IBloan-neighbors
    let solvent-counterparties counterparty-debtor with [bank-solvent?]
    ask solvent-counterparties [
        ask in-IBloan-from bank bank-number [

          ;; the interest payment is interest plus principal 
          ;; interbank markets are short-term
          
          set bank-interest-payment IB-amount * (1 + IB-rate)  
          set interbank-interests interbank-interests + bank-interest-payment
          ]
    ]
    set IB-interest-income interbank-interests 
  ]
end

to calculate-interbank-interest-expense [bank-number]
  let interbank-interests 0
  ask bank bank-number[
    let bank-interest-payment 0
    
    ;; it is assumed all bank counterparties are paid, even if bankrupt
    ;; one rationale is when banks go bankrupt, all credits are collected
    ;; rationale is same as for liquidating loans
    
    let counterparty-creditor in-IBloan-neighbors

    ask counterparty-creditor [
        ask out-IBloan-to bank bank-number [
          
          ;; the interest payment is interest plus principal
          ;; interbank markets are shor-term

          set bank-interest-payment IB-amount * ( 1 + IB-rate)
          set interbank-interests interbank-interests + bank-interest-payment
          ]
    ]
    set IB-interest-expense interbank-interests 
  ]
end

to calculate-interbank-net-interest-income [bank-number]
  ask bank bank-number[
    set IB-net-interest-income IB-interest-income - IB-interest-expense
  ]
end

to main-build-loan-book-locally
  
  let solvent-banks banks with [bank-capitalized?]
  
  ask solvent-banks [
    
    let desired-reserves-ratio min-reserves-ratio * buffer-reserves-ratio
    let bank-number who
    let interim-equity   equity
    let interim-rwa      rwassets
    let interim-reserves bank-reserves
    let interim-deposits bank-deposits
    let interim-capital-ratio capital-ratio
    let interim-reserves-ratio reserves-ratio
    let interim-loans   bank-loans
    let interim-provisions bank-provisions

    
    let available-loans loans with [loan-approved? = false and 
      loan-solvent? = true and 
      bank-id = bank-number]
    
    ask available-loans [
      
      set interim-capital-ratio (interim-equity - pdef * lgdamount )  / (interim-rwa + rwamount)
      set interim-reserves-ratio (interim-reserves - pdef * lgdamount - amount)/ interim-deposits    
      
      if (interim-capital-ratio > CAR and interim-reserves-ratio > desired-reserves-ratio) [

        set interim-rwa interim-rwa + rwamount
        set interim-equity interim-equity - pdef * lgdamount        
        set interim-reserves interim-reserves - amount - pdef * lgdamount
        set interim-loans interim-loans + amount
        set interim-provisions interim-provisions + pdef * lgdamount
        
        set loan-approved? true
        set bank-id bank-number
        set color yellow
      ]     
    ]
    
    set rwassets interim-rwa    
    set bank-reserves interim-reserves
    set bank-loans interim-loans
    set equity interim-equity 
    set bank-provisions interim-provisions
    set total-assets bank-reserves + bank-loans

    set capital-ratio interim-equity / interim-rwa    
    set reserves-ratio bank-reserves / bank-deposits
    set total-assets bank-reserves + bank-loans
    set leverage-ratio equity / total-assets
    
    set assets=liabilities? (equity + bank-deposits + IB-debits) - 
      (bank-loans + bank-reserves + IB-credits)
    

  ]
  
end


to main-risk-weight-optimization
  
  
  let banks-under-capitalized banks with [ not bank-capitalized? 
    and bank-solvent?]
  
  
  ask banks-under-capitalized [
    
    let bank-number who
   
    let loans-with-bank loans with [bank-id = bank-number and loan-approved? and
      loan-solvent?]
    

    
    if any? loans-with-bank [

        let interim-equity equity
        let interim-rwassets rwassets
        let interim-reserves bank-reserves
        let interim-deposits bank-deposits
        let interim-capital-ratio  capital-ratio
        let interim-reserve-ratio reserves-ratio
        let interim-loans bank-loans
        let interim-provisions bank-provisions


        let current-capital-ratio capital-ratio
        let current-equity equity
        let current-rwassets rwassets

        ;; the next procedure allows banks to evaluate the impact of dumping loans 
        ;; one-by-one
        ;; it works the following way 
        
        let n-dumped-loans 0       
        
        ask loans-with-bank [
          
          ;; loan-<>  variables denote internal loop variables used in 
          ;; ask loans-with-banks
          
          
          ;; the line below calculates
          ;;   
          let loan-equity         interim-equity - amount * fire-sale-loss + pdef * lgdamount
          
          
          let loan-rwassets       interim-rwassets - rwamount
          let loan-capital-ratio  loan-equity / loan-rwassets
          let loan-reserves       interim-reserves - amount * fire-sale-loss + pdef * lgdamount
          let loan-total-balance  interim-loans - amount
          let loan-provisions     interim-provisions - pdef * lgdamount
          let loan-deposits       interim-deposits
          
          ;; check if 
          ;;    loan-capital ratio > interim-capital-ratio
          ;;    loan-equity   > 0
          ;;    loan-rwassets > 0 
          ;; if this is the case:
          ;;    update equity, rwassets and capital ratio
          ;;    update deposits - increase by recovery at default
          ;;
          
          if ( loan-capital-ratio > interim-capital-ratio and
            loan-equity > 0 and 
            loan-rwassets > 0) [
            
            set interim-equity loan-equity
            set interim-rwassets loan-rwassets
            set interim-capital-ratio loan-capital-ratio
            set interim-reserves loan-reserves
            set interim-loans loan-total-balance
            set interim-provisions loan-provisions
            set interim-deposits interim-deposits - amount
            ;; discharge the loan from the loan-book
            ;; dumped loans are GRAY
                                    
            set loan-dumped? true
            set loan-approved? false    
            set color gray  
            
            set n-dumped-loans n-dumped-loans + 1
            
            ]
        ] ; end ask loans-with-bank
        
        ; calculate new balance sheet after risk weight optimization
        ; you can check if they are right with the following commands
        ;
        ; let dumped-loans loans with [bank-id = ? and loan-dumped? = true]
        ; let current-loans loans with [bank-id = ? and loan-solvent? and loan-approved? ]
        
        ; set equity equity - sum [ amount * fire-sale-loss] of dumped-loans
        ; set rwassets sum [rwamount] of current-loans 
        ; set bank-loans sum [ amount ] of current-loans
        
        set equity interim-equity
        set rwassets interim-rwassets
        set capital-ratio interim-capital-ratio
        set bank-reserves interim-reserves
        set bank-loans interim-loans
        set total-assets bank-reserves + bank-loans
        set leverage-ratio equity / total-assets
        set bank-provisions interim-provisions
        set reserves-ratio bank-reserves / bank-deposits
        
        ;; the following two lines create problems since it reports cumulative dumped-loans
        ;; hence, the n-dumped-loans in this optimization loop is overstated
        ;; we have it replaced 
        ;; 
               
        ; let dumped-loans loans with [bank-id = ? and loan-dumped? = true]        
        ; let n-dumped-loans count dumped-loans
        
        if capital-ratio > CAR [ 
          set color green
          set bank-capitalized? true
          ]
        
        
        ;; dumped savers are WHITE
               
        let savers-in-bank savers with [bank-id = bank-number and owns-account? = true]
        
        ifelse (n-dumped-loans < count savers-in-bank) [
          ask n-of n-dumped-loans savers-in-bank[
            set owns-account? false
            set color white          
          ] 
        ]
        [ ask savers-in-bank [
            set owns-account? false
            set color white
            ]
          set equity equity - (n-dumped-loans - count savers-in-bank)
          ]
        ]
        
        set bank-deposits sum[balance] of savers with [bank-id = bank-number and owns-account?]
    ]
end

;; this routine assumes excess capital is distributed to shareholders
;; the alternative is to expand the balance sheet in other banks' territories

to main-pay-dividends
  
  let capitalized-banks banks with [capital-ratio > CAR]
  
  ask capitalized-banks [
    let bank-number who

    ask bank bank-number [
      ifelse capital-ratio < upper-bound-cratio [
        ; do nothing
       
      ]       
      [
        ;; reduce excess capital
        ;; first by drawing reserves down to the floor
        ;; afterwards, by deleveraging
        
        let target-capital upper-bound-cratio * rwassets               
        let excess-capital equity - target-capital
               
        let reserves-floor min-reserves-ratio * bank-deposits * buffer-reserves-ratio
                
        let excess-reserves bank-reserves - reserves-floor
        
        ifelse excess-capital < excess-reserves [
          
          set bank-reserves bank-reserves - excess-capital
          set bank-dividend equity - target-capital          
          set bank-cum-dividend bank-cum-dividend + bank-dividend          
          set equity target-capital
          set capital-ratio equity / rwassets
          set total-assets bank-reserves + bank-loans
          set leverage-ratio equity / total-assets
         
        ][      
        
          set bank-reserves reserves-floor
                    
          ;;let excess-loans excess-capital - excess-reserves

          let interim-equity equity - excess-reserves
          ;; let interim-equity equity  :: this is the original line in the program
           
          let interim-rwassets rwassets
          let interim-reserves bank-reserves
          let interim-deposits bank-deposits
          
          let interim-capital-ratio interim-equity / interim-rwassets
          ;; let interim-capital-ratio  capital-ratio  :: original line in the progrma
          
          let interim-reserve-ratio bank-reserves / bank-deposits
          ;;let interim-reserve-ratio reserves-ratio
          
          let interim-loans   bank-loans
          
          let loans-with-bank loans with [bank-id = bank-number and 
            loan-approved? and 
            loan-solvent?]

          ask loans-with-bank [
          
            ;; loan-<>  variables denote internal loop variables used in 
            ;; ask loans-with-banks
            
            let loan-discount 0  ; no fire-sale of assets when paying dividends, 
                                 ; bank is not distressed
            
            let loan-equity         interim-equity - amount * loan-discount
            let loan-rwassets       interim-rwassets - rwamount
            let loan-capital-ratio  loan-equity / loan-rwassets
            ;; let loan-reserves       interim-reserves - amount * loan-discount
            let loan-total-balance  interim-loans - amount
         
            ;; check if 
            ;;    loan-capital ratio > interim-capital-ratio
            ;;    loan-equity   > 0
            ;;    loan-rwassets > 0 
            ;; if this is the case:
            ;;    update equity, rwassets and capital ratio
            ;;    update deposits - increase by recovery at default
            ;;
          
            if ( loan-capital-ratio < interim-capital-ratio and
              loan-capital-ratio >= upper-bound-cratio and
              loan-equity > 0 and 
              loan-rwassets > 0) [
           
              set interim-equity loan-equity
              set interim-rwassets loan-rwassets
              set interim-capital-ratio loan-capital-ratio
            ;;set interim-reserves loan-reserves
              set interim-loans loan-total-balance
            
            ;; discharge the loan from the loan-book
                                    
              set loan-dumped? true
              set loan-approved? false    
              set color 86  ; light blue
            ]
          ] ; end ask loans-with-bank
        
          set bank-dividend equity - interim-equity
          set bank-cum-dividend bank-cum-dividend + bank-dividend
          set equity interim-equity
          set rwassets interim-rwassets
          set capital-ratio equity / rwassets
          set bank-reserves bank-reserves - bank-dividend
          set total-assets bank-reserves + bank-loans
          set leverage-ratio equity / total-assets

        ] ; end if-else excess capital 

        ;; it may be the case that the resulting equity is not
        ;; the same as target-capital !!!        

      ] ; end if else capital ratio
     
    ] ; end ask bank
    
  ] ; ask capitalized-bank 
end

to main-reset-insolvent-loans
  
 ;; reset insolvent loans to keep lending opportunities steady for banks that succeed
 ;; in recapitalizing
 ;; note that lending opportunities for banks that do not recapitalize shrink
 ;; explains why slice is pie turns magenta
  
 let i 0
  while [ i < n-banks][
   let loans-insolvent-with-bank loans with [bank-id = i and 
        loan-approved? and not loan-solvent?]
   
   ask loans-insolvent-with-bank [
     set loan-solvent? true
     set loan-approved? false
     set color 107
   ]  
   set i i + 1
 ] ; end while 
end


to main-build-loan-book-globally
  
  let solvent-banks banks with [bank-capitalized?]
  let list-solvent-banks [who] of solvent-banks

;; create agentset of loans in neighborhoods of weak banks
;; use foreach command to identify individual neighborhood agent sets and 
;; merge them at the end

  let weak-banks banks with [not bank-capitalized? or not bank-solvent?]
  let list-weak-banks [who] of weak-banks

  let available-loans-elsewhere no-turtles            
  foreach list-weak-banks [
    
    let available-loans 
      loans with [loan-approved? = false and loan-solvent? = true and bank-id = ?] 
    
    set available-loans-elsewhere (turtle-set available-loans-elsewhere available-loans)
  ]
  ;; show "loans available elsewhere"
  ;; show count available-loans-elsewhere

  ;; Banks build their loan-book lending in their neighborhoods
  ;; afterwards, they start lending in the neighborhoods where 
  ;; other banks are insolvent or undercapitalized
  
  foreach list-solvent-banks[

    ask bank ? [
      ;; initial-balance-sheet data
      ;; 
      ;;
      let interim-equity   equity
      let interim-rwa      rwassets
      let interim-reserves bank-reserves
      let interim-deposits bank-deposits
      let interim-capital-ratio 0
      let interim-reserve-ratio reserves-ratio
      let interim-loans   bank-loans
      let interim-provisions bank-provisions
      
      ask available-loans-elsewhere [
        
        ;; note that if a loan is made, a corresponding general provision must be made
        
        set interim-capital-ratio (interim-equity - pdef * lgdamount )  / (interim-rwa + rwamount)        

        set interim-reserve-ratio (interim-reserves - pdef * lgdamount - amount)/ interim-deposits    
  
        if ( interim-capital-ratio > CAR and 
            interim-reserve-ratio > min-reserves-ratio)[
  
          set interim-rwa interim-rwa + rwamount
          set interim-reserves interim-reserves - amount - pdef * lgdamount
          set interim-loans interim-loans + amount
          set interim-equity interim-equity - pdef * lgdamount
          set interim-provisions interim-provisions + pdef * lgdamount

          
          set loan-approved? true      
          set bank-id ?  
          set color yellow
          ]
    
      ] ; end ask available-loan
      
    set rwassets interim-rwa    
    set bank-reserves interim-reserves
    set bank-loans interim-loans
    set equity interim-equity 
    set bank-provisions interim-provisions
    set total-assets bank-reserves + bank-loans
    
    ;; ratio has to be calculated since the last calculation in the available-loans loop
    ;; reports the first instance of the capital ratio that does not meet the CAR
    
    set capital-ratio interim-equity / interim-rwa    
    set reserves-ratio bank-reserves / bank-deposits
    set total-assets bank-reserves + bank-loans
    set leverage-ratio equity / total-assets
    
    set assets=liabilities? (equity + bank-deposits + IB-debits) - 
     (bank-loans + bank-reserves + IB-credits)
    
    ] ; end ask bank ? 
  ] ; end foreach list-solvent-banks 
  
 
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                           ;;
;; Main procedure for evaluating liquidity   ;;
;;                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to main-evaluate-liquidity
  
  ;; the four procedures will cause some banks to have:
  
  ;; excess reserves: bank-reserves > minimum-reserves
  ;; excess reserve deficit, reserves > 0
  ;;   borrow from banks with excess reserve surplus (if solvent and capitalized)
  ;;   reserve optimization if not capitalized
  ;; excess reserve deficit, reserves < 0
  ;;   bank facing liquidity run - cannot borrow from other banks
  ;;   reserve optimization - sell loans to build up reserves
  ;;
  
  
  ;; the deposit-<> procedures simulate the following shocks:
  
  ;;   process-deposit-withdrawal: a number of savers close their accounts
  ;;   process-deposit-reassignment: and open accounts with other banks
  ;;     both process-deposit-withdrawal and -reassignment are liquidity-neutral
  ;;     system-wide
  ;;   process-deposit-flow-rebalancing: all bank-deposits and bank-reserves are 
  ;;     adjusted to reflect the movement in reserves
 
  
  process-deposit-withdrawal
  process-deposit-reassignment
  process-deposit-flow-rebalancing
  process-evaluate-liquidity-needs

  
end

;;-----------------------------------------
;; Subprocedures of main-evaluate-liquidity
;;-----------------------------------------


to process-deposit-withdrawal
  
  ;; savers withdraw funds from solvent banks
  ;; banks that are insolvent have already liquidated their loan portfolio and 
  ;; returned their deposits to savers
  
  
  let solvent-banks banks with [bank-solvent?]
  
  if any? solvent-banks [
  
    ask solvent-banks [
      let bank-number who
      let savers-with-bank savers with [bank-id = bank-number and saver-solvent? and owns-account?]
     
      ask savers-with-bank [
        let withdraw-shock random 101
        set withdraw-shock withdraw-shock / 100
        if withdraw-shock < withdraw-prob [
          set bank-id 9999
          set owns-account? false
          set saver-last-color color
          set color red
        ]
      ]
      ask bank bank-number [
        set deposit-outflow sum [balance] of savers-with-bank with [bank-id = 9999]
        
        ;; uncomment this line
        
      ]
    ] ;; ask-solvent-banks
    
  ] ;; end if any? 

  
;;  let i 0
 
;;  while [i < n-banks][
;;    let savers-with-bank savers with [bank-id = i and saver-solvent?]
;;    ask savers-with-bank [
;;      let withdraw-shock random 101
;;      set withdraw-shock withdraw-shock / 100
;;      if withdraw-shock < withdraw-prob [
;;        set bank-id 9999
;;        set saver-last-color color
;;        set color red
;;      ]
;;    ]
;;    ask bank i [set deposit-outflow 
;;      sum [balance] of savers-with-bank with [bank-id = 9999]
;;    ]
;;    set i i + 1
;;  ]
  
end


to process-deposit-reassignment
  
  ;; deposits are reassigned to capitalized banks first, and to solvent banks
  ;; if no capitalized bank exist
  
  
  let deposit-withdrawn savers with [bank-id = 9999]
  let list-capitalized-banks [who] of 
    banks with [bank-solvent? and bank-capitalized?]
    
  let list-solvent-banks [who] of banks with [bank-solvent?]
  let list-recipient-banks []
    
  ifelse not empty? list-capitalized-banks 
  [ set list-recipient-banks list-capitalized-banks ]
  [ set list-recipient-banks list-solvent-banks ]
    
  ask deposit-withdrawn[
    
    ;; choose a random bank from the list of recipient banks
    
    let bank-number random (length list-recipient-banks)
    
    set bank-id (item bank-number list-recipient-banks)
    
;    pen-down   
;    set pen-size 1.5
    move-to one-of patches with [patch-region-id = bank-number]
    set owns-account? true
    set color saver-last-color
  ]    
  
  ;; reassigning saver to different bank
  ;; move saver to bank neighborhood
  ;; but only if bank is solvent and not undercapitalized
  

;  clear-drawing
;  subroutine-draw-sectors
  
  let solvent-banks banks with [bank-solvent?]
  
  ask solvent-banks [
    let bank-number who
    set deposit-inflow sum [balance] of 
      deposit-withdrawn with [bank-id = bank-number and owns-account?]
    set net-deposit-flow deposit-inflow - deposit-outflow
  ]

end


to process-deposit-flow-rebalancing
  
  ask banks with [bank-solvent?] [    
    
    set bank-deposits bank-deposits + net-deposit-flow
    set bank-reserves bank-reserves + net-deposit-flow
    set reserves-ratio bank-reserves / bank-deposits
    set total-assets bank-reserves + bank-loans
    set deposit-inflow 0
    set deposit-outflow 0
    set net-deposit-flow 0
        
    ]
 
end

 
to process-evaluate-liquidity-needs
  
  ask banks with [bank-solvent?] [
    set reserves-ratio bank-reserves / bank-deposits
  ]
    
  ; Find liquid and well capitalized banks

  
  let liquid-capitalized-banks banks with [reserves-ratio > min-reserves-ratio and 
    capital-ratio >= CAR]
  
  ; Find banks that have experienced bank runs, i.e. negative reserves
  ; in this case, banks go bankrupt and assets are sold to pay depositors

   
  let banks-with-bank-run banks with [reserves-ratio < 0]   
  ask banks-with-bank-run [
    let bank-number who
    process-unwind-loans-insolvent-bank bank-number bankrupt-liquidation
    set color brown
    set liquidity-failure? true
  ]
  
  ; Find banks that are well capitalized and experiencing a shortage of reserves


  let not-liquid-capitalized-banks banks with [reserves-ratio < min-reserves-ratio and
    capital-ratio >= CAR]  
  ask not-liquid-capitalized-banks [    
    let bank-number who 
    set color yellow
    process-access-interbank-market bank-number
  ]
  
  ; Recalculate the number of banks experiencing shortages of reserves
  ; it could be the case that some banks attempting to find resources were not
  ; able to find all the resources they needed
  
   
   
  let not-liquid-not-capitalized-banks banks with [ 
    reserves-ratio < min-reserves-ratio and
    reserves-ratio > 0 and not bank-capitalized? and bank-solvent?]
  ask not-liquid-not-capitalized-banks [ set color yellow]
   
 
end

to process-access-interbank-market [bank-number]
  
    let liquid-banks banks with [reserves-ratio > buffer-reserves-ratio * min-reserves-ratio 
      and capital-ratio >= CAR]
    
    ask liquid-banks [set color green]
 
    ask bank bank-number [
      let current-reserves bank-reserves
      let needed-reserves min-reserves-ratio * bank-deposits  - bank-reserves
;;      set needed-reserves needed-reserves
      
      set color yellow
      
      let available-reserves 
        sum [(bank-reserves - buffer-reserves-ratio * min-reserves-ratio * bank-deposits)] of liquid-banks
       
      let liquidity-contribution 0
      
      create-ibloans-from liquid-banks
      
      let IB-request 0  
      ifelse needed-reserves < available-reserves [
        set IB-request needed-reserves][
        set IB-request available-reserves]
            
      ask liquid-banks[ 
        let liquid-bank-id who
        let excess-reserve (bank-reserves - buffer-reserves-ratio * min-reserves-ratio * bank-deposits)
        set liquidity-contribution  excess-reserve * IB-request / available-reserves
        set bank-reserves bank-reserves - liquidity-contribution  ; reduce asset side of balance-sheet
        set IB-credits IB-credits + liquidity-contribution        ; but offset by IB-credit in the asset side
        set reserves-ratio bank-reserves / bank-deposits
        
        ask ibloan liquid-bank-id bank-number [
          set ib-amount liquidity-contribution
          set ib-rate LIBOR-rate
          set color red
          set thickness 3
        ]
        
      ] ; ask liquid banks
      
      set IB-debits IB-request
      set bank-reserves bank-reserves + IB-debits      
      set reserves-ratio bank-reserves / bank-deposits
      set total-assets bank-reserves + bank-loans
      
      set assets=liabilities? (equity + bank-deposits + IB-debits) - 
        (bank-loans + bank-reserves + IB-credits)


;;      create-ibloans-from liquid-banks
;;      ask my-in-links [ 
;;        set ib-amount liquidity-contribution
;;        set ib-rate LIBOR-rate
;;        set color red]
      
    ] ; ask bank bank-number
end


;; the procedure write-interbank-links saves the in-links ibloans of each bank
;; in the matrix-interbank-exposures, and then writes it to the file interbank
;; exposure. Row [j] corresponds to the interbank debits of bank j to other banks


to main-write-interbank-links
  
  let matrix-interbank  matrix:make-identity  n-banks
  let list-my-bank-creditors []
  let my-bank-creditors []
  
  
  ask banks [
    let bank-number who
    set my-bank-creditors in-ibloan-neighbors
    ;;show in-ibloan-neighbors
    set list-my-bank-creditors [who] of my-bank-creditors
    set list-my-bank-creditors sort list-my-bank-creditors
    ;;show list-my-bank-creditors

    if not empty? list-my-bank-creditors [
      foreach list-my-bank-creditors[
        ask ibloan ? bank-number [
          matrix:set matrix-interbank bank-number ? ib-amount
        ]
      ]
    ]  ;; end if not empty
  ] ;; end ask banks
  
  ;; write output to file 
  file-open "interbank-exposure.csv"
  file-type idx-simulations file-type " "
  file-print matrix-interbank
  
end 

to main-write-bank-ratios
  
  ;; matrix-bank-ratios stores the following variables for each bank
  ;;
  ;; 1  capital-ratio
  ;; 2  reserves-ratio
  ;; 3  leverage-ratio
  ;; 4  upperbound-cratio
  ;; 5  buffer-reserves-ratio
  ;; 6  CAR
  ;; 7  min-reserves-ratio
  ;; 8  bank-dividends
  ;; 9  bank-cum-dividends
  ;; 10  bank-loans
  ;; 11  bank-reserves
  ;; 12 bank-deposits
  ;; 13 equity
  ;; 14 total-assets
  ;; 15 rwassets
  ;; 16 credit-failure-indicator
  ;; 17 liquidity-failure-indicator
  
  let matrix-bank-ratios matrix:make-constant n-banks 17 0 
   
  ask banks [
    let credit-failure-indicator 0
    let liquidity-failure-indicator 0
    let bank-number who
    matrix:set matrix-bank-ratios bank-number 0 CAR
    matrix:set matrix-bank-ratios bank-number 1 min-reserves-ratio        
    matrix:set matrix-bank-ratios bank-number 2 capital-ratio
    matrix:set matrix-bank-ratios bank-number 3 reserves-ratio
    matrix:set matrix-bank-ratios bank-number 4 leverage-ratio
    matrix:set matrix-bank-ratios bank-number 5 upper-bound-cratio
    matrix:set matrix-bank-ratios bank-number 6 buffer-reserves-ratio
    matrix:set matrix-bank-ratios bank-number 7 bank-dividend
    matrix:set matrix-bank-ratios bank-number 8 bank-cum-dividend
    matrix:set matrix-bank-ratios bank-number 9 bank-loans
    matrix:set matrix-bank-ratios bank-number 10 bank-reserves
    matrix:set matrix-bank-ratios bank-number 11 bank-deposits
    matrix:set matrix-bank-ratios bank-number 12 equity
    matrix:set matrix-bank-ratios bank-number 13 total-assets
    matrix:set matrix-bank-ratios bank-number 14 rwassets
    ifelse credit-failure? [set credit-failure-indicator 1] 
      [set credit-failure-indicator 0]
    ifelse liquidity-failure? [set liquidity-failure-indicator 1] 
      [set liquidity-failure-indicator 0]
    matrix:set matrix-bank-ratios bank-number 15 credit-failure-indicator
    matrix:set matrix-bank-ratios bank-number 16 liquidity-failure-indicator
  
  ]

  file-open "bank-ratios.csv"
  file-type idx-simulations file-type " "
  file-print matrix-bank-ratios
  
  
end

to main-raise-deposits-build-loan-book
  
  let over-capitalized-banks banks with [capital-ratio > upper-bound-cratio]
  let available-savers savers with [saver-solvent? and not owns-account?]
  let available-loans loans with [loan-solvent? and not loan-approved?]
  
  ask over-capitalized-banks[
    let bank-number who
    ask available-savers [
      set bank-id bank-number 
      set owns-account? true
    ]
    set bank-reserves bank-reserves + sum [balance] of available-savers
    set bank-deposits bank-deposits + sum [balance] of available-savers
    set total-assets bank-reserves + bank-deposits
    
    let interim-equity   equity
    let interim-rwa      rwassets
    let interim-reserves bank-reserves
    let interim-deposits bank-deposits
    let interim-capital-ratio capital-ratio
    let interim-reserve-ratio reserves-ratio
    let interim-loans   bank-loans
    let interim-provisions bank-provisions
      
    ask available-loans [
      
      ;; note that if a loan is made, a corresponding general provision must be made
      
      set interim-capital-ratio (interim-equity - pdef * lgdamount )  / (interim-rwa + rwamount)        

      set interim-reserve-ratio (interim-reserves - pdef * lgdamount - amount)/ interim-deposits    

      if ( interim-capital-ratio > CAR and 
          interim-reserve-ratio > min-reserves-ratio)[

        set interim-rwa interim-rwa + rwamount
        set interim-reserves interim-reserves - amount - pdef * lgdamount
        set interim-loans interim-loans + amount
        set interim-equity interim-equity - pdef * lgdamount
        set interim-provisions interim-provisions + pdef * lgdamount

        set loan-approved? true      
        set bank-id bank-number  
        set color yellow
        ]
  
    ] ; end ask available-loan
      
    set rwassets interim-rwa    
    set bank-reserves interim-reserves
    set bank-loans interim-loans
    set equity interim-equity 
    set bank-provisions interim-provisions
    set total-assets bank-reserves + bank-loans
    
    ;; ratio has to be calculated since the last calculation in the available-loans loop
    ;; reports the first instance of the capital ratio that does not meet the CAR
    
    set capital-ratio interim-equity / interim-rwa    
    set reserves-ratio bank-reserves / bank-deposits
    set total-assets bank-reserves + bank-loans
    set leverage-ratio equity / total-assets
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Auxiliary Procedures
;;


to-report subroutine-find-hood [a]
  let hood table:get table-sector a
  report hood
end


  

  
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1021
842
400
400
1.0
1
10
1
1
1
0
0
0
1
-400
400
-400
400
1
1
1
ticks
30.0

BUTTON
31
11
197
44
Run program 
main-run-program-recursive
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This is the NetLogo implementation of ABBA, the agent-based model of the banking system described in _Chan-Lau, J.A., 2014, "Regulatory Requirements and their Implications for Bank Solvency, Liquidity and Interconnectedness Risks: Insights from Agent-Based Model Simulations."_ The paper is available from the SSRN archives at: http://ssrn.com/abstract=2537124

The model runs in NetLogo 5.1 and has not been checked for backward compatibility.

The author can be contacted at: jchanlau@imf.org


## HOW IT WORKS

The NetLogo implementation of ABBA considers one type of agent, the banks, and three protoagents: savers, loans, and interbank loans. While the latter are not agents per se, interbank loans are links and considered as individual agents in NetLogo.

In this model, banks use savers' deposits to fund loans, both of which are in the amount of one unit. The loans are risky, with  probability of default sampled from a uniform distribution with support in [0 0.10]. When extending loans, banks quote lending rates set equal to a markup over the fair lending rate accounting for the loan's probability of default and recovery rate. Banks also need to provision agains the expected loss of the loan. Regulatory requirements specify that banks' equity to risk-weighted assets should exceed a minimum capital adequacy ratio, and that banks should hold cash reserves to deposits above a minimum reserve ratio.

### Model dynamics

After building a loan portfolio, banks experience credit shocks affecting the portfolio in every period. After accounting for net interest income and the change in provisions, banks may be either well capitalized (capital ratio above CAR), solvent but undercapitalized, or bankrupt (zero or negative capital ratio). Solvent banks may attempt to raise their capital ratio performing risk-weight optimization, i.e. deleveraging their loan book. Bankrupt banks are forced to unwind their loan book, and will cause losses to other banks that have lent their money in the interbank market. These second-round losses are then added to the initial credit losses experienced by the banks until no additional bank fails.

Once solvent banks have optimized their portfolios, banks may consider paying dividends or not. The motivation for dividend payments is that banks prefer their capital ratio not to exceed a certain internal target. If the target is exceeded, the bank will pay dividends provided the remaining amount of reserves it holds meets the minimum reserve ratio. 

After dividends are paid, savers received their deposit interests and decide whether they keep their deposit principal in the same bank or shift banks randomly. Only well capitalized banks can be recipients of new deposits. Some banks may experience a net negative liquidity shock, as deposit withdrawals may exceed deposit inflows, and may not be able to meet reserve requirements. If the bank is well capitalized, it can access the interbank market, borrowing from banks enjoying excess reserves, generating an endogenous bank network.

Then the cycle starts again. This is an oversimplified description of the model, please see the above mentioned reference for full details.


## HOW TO USE IT

The user interface has no bells and whistles. There is just one button that starts the model, RUN PROGRAM, as the program has been designed with the purpose of conducting the data analysis outside the NetLogo environment, using ASCII output files. Typically, sensitivity analysis in NetLogo programs can be performed using BehaviorSpace. But the standard output of BehaviorSpace proved too cumbersome for manipulating the large number of variables required in the data analysis. Matlab or R are highly recommended for the data analysis.

The regulatory requirements of the model can be changed in the procedure MAIN_RUN_PROGRAM_RECURSIVELY by modifying the lines let-list-CAR and let-list-reserves-ratio. 

The main output of the program is contained in two ASCII files. The first file, bank-ratios.csv, contains data on 17 indicators. Each row in the file contains the 17 indicators for each of the banks in the system, indicating the period in the simulation as well as the given values for the regulatory requirements. The specific indicators are listed in the procedure main-write-bank-ratios.

The second file, interbank-exposure.csv, stores the interbank exposure matrix in a single row. For instance, in the case of 10 banks, the matrix is rearranged in a single vector, where the first 10 numbers correspond to the interbank loans incurred by the first bank, and so on. See details in the procedure main-write-interbank-links

To facilitate implementation, a modular approach is followed. Main procedures are preceded by the word MAIN, which call processes (preceded by the word PROCESS). The main procedures and processes perform calculations using the routines preceded by the word CALCULATE. Parameters that can be set up by the user are grouped in several SETUP routines. 

## THINGS TO NOTICE

The graphical interface creates a circular world, divided in circular sectors (like a pizza) with one bank placed in each sector. While the model is running, interbank linkages will appear connecting banks. Solvent banks are colored green, illiquid banks yellow, banks that failed due to credit shocks red, and banks that failed due to liquidity shocks brown.

Computations are slow so turning the graphical mode is advised for a large number of simulations or long periods in each simulation. As an indication, in a model with 10 banks, running 100 simulations, each comprising 240 periods for 12 possible combinations of regulatory requirements required four full days in two core i7 Windows 7 computers, each with 8 Gb of memory.



## EXTENDING THE MODEL

Potential model extensions are discussed in the reference. 

## CREDITS AND REFERENCES

Chan-Lau, J.A., 2014, "Regulatory Requirements and their Implications for Bank Solvency, Liquidity and Interconnectedness Risks: Insights from Agent-Based Model Simulations." Mimeo, International Monetary Fund; R.H.Smith School of Business, U of Maryland; and Risk Management Institute, National University of Singapore.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Experiment 1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup-behavior-space</setup>
    <go>main-run-program-behavior-space</go>
    <steppedValueSet variable="idx_simulations" first="1" step="1" last="100"/>
    <enumeratedValueSet variable="CAR">
      <value value="0.04"/>
      <value value="0.08"/>
      <value value="0.12"/>
      <value value="0.16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-reserves-ratio">
      <value value="0.015"/>
      <value value="0.03"/>
      <value value="0.045"/>
      <value value="0.06"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

curved link
50.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
