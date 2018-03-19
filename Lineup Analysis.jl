#=
This code implements the No Stacking baseball
=#

# To install DataFrames, simply run Pkg.add("DataFrames")
using DataFrames

# To install MathProgBase, simply run Pkg.add("MathProgBase")
using MathProgBase

include("Data Cleaning.jl")

#=
GLPK is an open-source solver, and additionally Cbc is an open-source solver. This code uses GLPK
because we found that it was slightly faster than Cbc in practice. For those that want to build
very sophisticated models, they can buy Gurobi. To install GLPKMathProgInterface, simply run
Pkg.add("GLPKMathProgInterface")
=#
using GLPKMathProgInterface
using Gurobi
# Once again, to install run Pkg.add("JuMP")
using JuMP

include("Baseball Formulations.jl")
 #this code has all the different formualations
# include("C:/Users/Arjun Mithal/Documents/DraftKings/Variance Compiler.jl")


#####################################################################################################################
#####################################################################################################################
function contets_rank(lineup_pts,contest_pts)
	lineup_pts_sort = sort(lineup_pts,rev=true)
	contest_pts_sort = float(sort(contest_pts))
	n = size(contest_pts_sort)[1]
	rank_in_contest=[]
	for pts in lineup_pts_sort
		rank = 1+size(filter(x->pts<x,contest_pts_sort))[1]
		rank_in_contest=[rank_in_contest;rank]
	end
	return rank_in_contest
end

function create_lineups(num_lineups, num_overlap, path_pitchers,path_hitters, formulation, path_to_output,path_to_ID,stack_order,nstacks)
    #=
    num_lineups is an integer that is the number of lineups
    num_overlap is an integer that gives the overlap between each lineup
    path_pitchers,path_hitters is a string that gives the path to the players csv file
    formulation is the type of formulation you would like to use (for instance one_lineup_Type_1, one_lineup_Type_2, etc.)
    path_to_output is a string where the final csv file with your lineups will be
    =#

    println("loading data")
    players = merge_dk_dfn(path_hitters,path_pitchers,path_to_ID);

		#players_cov = merge_dk_cov(cov,path_hitters,path_pitchers,path_to_ID)
		# println(players_cov)
    # Number of players
    num_players = size(players)[1]

    # Create team indicators from the information in the players file
    teams = unique(players[:Team])

    num_teams = size(teams)[1]
    println(num_teams," teams playing tonight")

    # Create team indicators from the information in the players file
    games = unique(players[:Game])
    num_games = size(games)[1]
    println(num_games," games playing tonight")

	# arrays that store the information on which players are which position
    P = Array(Int64, 0);
    B1 = Array(Int64, 0);
    B2 =Array(Int64, 0);
    B3 =Array(Int64, 0);
    C =Array(Int64, 0);
    SS=Array(Int64, 0);
    OF=Array(Int64, 0);
    RP=Array(Int64, 0);


    #=
    Process the position information in the skaters file to populate the position and order
    #arrays  with the corresponding correct information
    =#
    for i =1:num_players
        pos = players[i,:Pos];
        #print(players[i,:Player_Name]," ",pos,"\n")
        if contains(pos,"SP")
            P=vcat(P,fill(1,1))
            B1=vcat(B1,fill(0,1))
            B2=vcat(B2,fill(0,1))
            B3=vcat(B3,fill(0,1))
            C=vcat(C,fill(0,1))
            SS=vcat(SS,fill(0,1))
            OF=vcat(OF,fill(0,1))
            RP=vcat(RP,fill(0,1))


        elseif contains(pos,"RP")
            P=vcat(P,fill(0,1))
            RP=vcat(RP,fill(1,1))
            B1=vcat(B1,fill(0,1))
            B2=vcat(B2,fill(0,1))
            B3=vcat(B3,fill(0,1))
            C=vcat(C,fill(0,1))
            SS=vcat(SS,fill(0,1))
            OF=vcat(OF,fill(0,1))

        elseif contains(pos,"1B")
            P=vcat(P,fill(0,1))
            B1=vcat(B1,fill(1,1))
            B2=vcat(B2,fill(0,1))
            B3=vcat(B3,fill(0,1))
            C=vcat(C,fill(0,1))
            SS=vcat(SS,fill(0,1))
            OF=vcat(OF,fill(0,1))
            RP=vcat(RP,fill(0,1))

        elseif contains(pos,"2B")
            P=vcat(P,fill(0,1))
            B1=vcat(B1,fill(0,1))
            B2=vcat(B2,fill(1,1))
            B3=vcat(B3,fill(0,1))
            C=vcat(C,fill(0,1))
            SS=vcat(SS,fill(0,1))
            OF=vcat(OF,fill(0,1))
            RP=vcat(RP,fill(0,1))

        elseif contains(pos,"3B")
            P=vcat(P,fill(0,1))
            B1=vcat(B1,fill(0,1))
            B2=vcat(B2,fill(0,1))
            B3=vcat(B3,fill(1,1))
            C=vcat(C,fill(0,1))
            SS=vcat(SS,fill(0,1))
            OF=vcat(OF,fill(0,1))
            RP=vcat(RP,fill(0,1))

        elseif contains(pos,"C")
            P=vcat(P,fill(0,1))
            B1=vcat(B1,fill(0,1))
            B2=vcat(B2,fill(0,1))
            B3=vcat(B3,fill(0,1))
            C=vcat(C,fill(1,1))
            SS=vcat(SS,fill(0,1))
            OF=vcat(OF,fill(0,1))
            RP=vcat(RP,fill(0,1))

        elseif contains(pos,"SS")
            P=vcat(P,fill(0,1))
            B1=vcat(B1,fill(0,1))
            B2=vcat(B2,fill(0,1))
            B3=vcat(B3,fill(0,1))
            C=vcat(C,fill(0,1))
            SS=vcat(SS,fill(1,1))
            OF=vcat(OF,fill(0,1))
            RP=vcat(RP,fill(0,1))

        elseif contains(pos,"OF")
            P=vcat(P,fill(0,1))
            B1=vcat(B1,fill(0,1))
            B2=vcat(B2,fill(0,1))
            B3=vcat(B3,fill(0,1))
            C=vcat(C,fill(0,1))
            SS=vcat(SS,fill(0,1))
            OF=vcat(OF,fill(1,1))
            RP=vcat(RP,fill(0,1))

        else
        	println("\t",players[i,:Player_Name]," has no position\n")

        end
    end


    #GAMES:   player_info stores information on which game each player is on
    player_info = zeros(Int, num_games)

    # Populate player_info with the corresponding information
    for j=1:num_games
        if players[1, :Game] == games[j]
            player_info[j] =1
        end
    end
    players_games = player_info'

    for i=2:num_players
        player_info = zeros(Int, num_games)
        for j=1:num_games
            if players[i, :Game] == games[j]
                player_info[j] =1
            end
        end
        players_games = vcat(players_games, player_info')
    end

    #TEAMS:   player_info stores information on which team each player is on
    player_info = zeros(Int, num_teams)

    # Populate player_info with the corresponding information
    for j=1:size(teams)[1]
        if players[1, :Team] == teams[j]
            player_info[j] =1
        end
    end
    players_teams = player_info'

    for i=2:num_players
        player_info = zeros(Int, num_teams)
        for j=1:size(teams)[1]
            if players[i, :Team] == teams[j]
                player_info[j] =1
            end
        end
        players_teams = vcat(players_teams, player_info')
    end

    #OPPONENT TEAM player_info stores information on which team each player is opposing
    player_info = zeros(Int, num_teams)

    # Populate player_info with the corresponding information
    for j=1:num_teams
    	if players[1, :Opp][1]=='@'
    		opp = players[1, :Opp][2:end]
    	else
    		opp = players[1, :Opp]
    	end

        if opp == teams[j]
            player_info[j] =1
        end
    end
    players_opp = player_info'

    for i=2:num_players
        player_info = zeros(Int, num_teams)
        for j=1:size(teams)[1]
          if players[i, :Opp][1]=='@'
    				opp = players[i, :Opp][2:end]
    			else
    				opp = players[i, :Opp]
    			end
          if opp == teams[j]
            player_info[j] =1
          end
        end
        players_opp = vcat(players_opp, player_info')
    end

    #STACK player_info stores information on which team each player is on
    num_stacks = 9;  #number of stacks

    #make matrix for 1st stacking (stacking_order[1])
    player_info = zeros(Int,num_stacks);

    # Populate player_info with the corresponding information, start with the first player to initiate the array
    for j=1:num_stacks
        if players[1,:Batting_Order_Confirmed_] == j
        	stack_ind = circshift(collect(1:9),stack_order-j)[1:stack_order[1]];  #index of the stacks this batting order belongs to.
        	#For ex., batting order 1, stacking order 3, will belong to (8,9,1),(9,1,2) and (1,2,3)
        	for k in stack_ind
        		player_info[k]=1;
        	end
        end
    end
    players_stacks1 = player_info';

    #now update the stack matrix of players 2 to num_players
    for i=2:num_players
    	player_info = zeros(Int,num_stacks);
        for j=1:num_stacks
            if players[i,:Batting_Order_Confirmed_] == j
        		stack_ind = circshift(collect(1:9),stack_order-j)[1:stack_order[1]];  #index of the stacks this batting order belongs to.
        		#For ex., batting order 1, stacking order 3, will belong to (8,9,1),(9,1,2) and (1,2,3)
        		for k in stack_ind
        			player_info[k]=1;
        		end
        	end
        end
        players_stacks1 = vcat(players_stacks1, player_info');
    end

    #make matrix for 2nd stacking (stacking_order[2])
    player_info = zeros(Int,num_stacks);

    # Populate player_info with the corresponding information, start with the first player to initiate the array
    for j=1:num_stacks
        if players[1,:Batting_Order_Confirmed_] == j
        	stack_ind = circshift(collect(1:9),stack_order-j)[1:stack_order[2]];  #index of the stacks this batting order belongs to.
        	#For ex., batting order 1, stacking order 3, will belong to (8,9,1),(9,1,2) and (1,2,3)
        	for k in stack_ind
        		player_info[k]=1;
        	end
        end
    end
    players_stacks2 = player_info';

    #now update the stack matrix of players 2 to num_players
    for i=2:num_players
    	player_info = zeros(Int,num_stacks);
        for j=1:num_stacks
            if players[i,:Batting_Order_Confirmed_] == j
        		stack_ind = circshift(collect(1:9),stack_order-j)[1:stack_order[2]];  #index of the stacks this batting order belongs to.
        		#For ex., batting order 1, stacking order 3, will belong to (8,9,1),(9,1,2) and (1,2,3)
        		for k in stack_ind
        			player_info[k]=1;
        		end
        	end
        end
        players_stacks2 = vcat(players_stacks2, player_info');
    end


    ###########################################################################
	#my formulation is:  formulation(players, old_lineups, num_overlap, num_players, num_games, P,B1,B2,B3,C,SS,OF,
	#                                 players_teams, players_opp, players_games,players_stacks1,players_stacks2,
	#                                 stack_order,nstacks)

    # Lineups using formulation as the stacking type

    println("Calculating lineup 1 of ", num_lineups)

    the_lineup  = formulation(players, hcat(zeros(Int, num_players), zeros(Int, num_players)), num_overlap, num_players,num_games,
                              P,B1,B2,B3,C,SS,OF, players_teams, players_opp, players_games,players_stacks1,players_stacks2,
	                          stack_order,nstacks)

    println("Calculating lineup 2 of ", num_lineups)

    the_lineup2 = formulation(players, hcat(the_lineup, zeros(Int, num_players)), num_overlap, num_players,num_games,
                              P,B1,B2,B3,C,SS,OF, players_teams, players_opp, players_games,players_stacks1,players_stacks2,
							 stack_order,nstacks)

    tracer = hcat(the_lineup, the_lineup2)
    for i=1:(num_lineups-2)
        println("Calculating lineup ", i+2, " of ", num_lineups)
        try
            thelineup = formulation(players, tracer, num_overlap, num_players,num_games,
                              P,B1,B2,B3,C,SS,OF, players_teams, players_opp, players_games,players_stacks1,players_stacks2,
	                          stack_order,nstacks)
            tracer = hcat(tracer,thelineup)
        catch
        	print("some optimization error")
            break
        end
    end

 # Create the output csv file
    #should be in format P  P   C   1B  2B  3B  SS  OF  OF  OF
    lineup2 ="P,P,C,1B,2B,3B,SS,OF,OF,OF,Proj_pts,Actual_pts, Salary, Vegas, Variance, Ceiling, Covariance\n"
    preal_max = 0
    Preal = []
    for j = 1:size(tracer)[2]
        lineup = ["" "" "" "" "" "" "" "" "" ""]
        #should be in format P  P   C   1B  2B  3B  SS  OF  OF  OF
        for i =1:num_players
            if tracer[i,j] == 1
            	#print("\tlineup ", j," player ", i, ":", string(players[i,1]),"\n")
                if P[i]==1
                    if lineup[1]==""
                        lineup[1] = string(players[i,1])
                    elseif lineup[2]==""
                        lineup[2] = string(players[i,1])
                    end
                elseif C[i]==1
                    if lineup[3]==""
                        lineup[3] = string(players[i,1])
                    end
                elseif B1[i]==1
                    if lineup[4]==""
                        lineup[4] = string(players[i,1])
                    end
                elseif B2[i]==1
                    if lineup[5]==""
                        lineup[5] = string(players[i,1])
                    end
                elseif B3[i]==1
                    if lineup[6]==""
                        lineup[6] = string(players[i,1])
                    end

                elseif SS[i]==1
                    if lineup[7]==""
                        lineup[7] = string(players[i,1])
                    end
                elseif OF[i]==1
                    if lineup[8]==""
                        lineup[8] = string(players[i,1])
                    elseif lineup[9]==""
                        lineup[9] = string(players[i,1])
                    elseif lineup[10]==""
                        lineup[10] = string(players[i,1])
                    end
                else
                	print(players[i,1]," has no position:",P[i],C[i],B1[i],B2[i],B3[i],SS[i],OF[i]"\n")
                end
            end
        end


        LineupOK = true
        lineup3 =""

        ppred = 0  #predicted points
        preal = 0  #actual points
        pvar = 0
        adj_var = 0
        pf = 0
        pdiff = 0
        new_adj = 0
        cfp = 0
        sal = 0
        proj_diff = 0
				vegas = 0
				pwisecov = 0
        for name in lineup
        	lineup3 = string(lineup3, name, ",")
        	for i =1:num_players
        		if string(players[i,1])==string(name)
                pvar = pvar+players[i,:Variance]
            		ppred  = ppred+players[i,:Proj_FP]
            		preal = preal +players[i,:Actual_FP]

                cfp = cfp +players[i, :Ceiling]
                sal = sal +players[i, :Salary]
								vegas = vegas +players[i, :Vegas]

            	end
            end
        end

        Preal = [Preal;preal]
        lineup3 = chop(lineup3)  #remove extra comma
        lineup3 = string(lineup3,",",ppred,",",preal, ",", sal, ",", vegas, ",", pvar, ",", cfp, ",", pwisecov, "\n")
        lineup2 = string(lineup2,lineup3)
        preal_max = max(preal,preal_max)
        #print("lineup ",j," actual points = ",preal,"\n")

    end

    path_contest = searchdir(folder,"contest")
    Preal_sort = sort(Preal,rev=true)
    Pcontest = float(readtable(path_contest)[:Points])
    ncontest = size(Pcontest)[1]
    R = contets_rank(Preal,Pcontest )
    nprofit = size(filter(x->x<0.2*ncontest,R))[1] #number of lineups that make money

		totalprofit = 0
		for i in 1:num_lineups
			if R[i] == 1
				totalprofit+=10000
			elseif R[i] == 2
				totalprofit+=6000
			elseif R[i] == 3
				totalprofit+=4000
			elseif R[i] == 4
				totalprofit+=2500
			elseif R[i] == 5
				totalprofit+=1500
			elseif R[i] == 6
				totalprofit+=1000
			elseif R[i] <= 8
				totalprofit+=750
			elseif R[i] <= 10
				totalprofit+=500
			elseif R[i] <= 15
				totalprofit+=400
			elseif R[i] <= 20
				totalprofit+=300
			elseif R[i] <= 25
				totalprofit+=250
			elseif R[i] <= 35
				totalprofit+=200
			elseif R[i] <= 50
				totalprofit+=150
			elseif R[i] <= 75
				totalprofit+=125
			elseif R[i] <= 100
				totalprofit+=100
			elseif R[i] <= 125
				totalprofit+=80
			elseif R[i] <= 150
				totalprofit+=60
			elseif R[i] <= 200
				totalprofit+=50
			elseif R[i] <= 250
				totalprofit+=40
			elseif R[i] <= 300
				totalprofit+=35
			elseif R[i] <= 400
				totalprofit+=30
			elseif R[i] <= 500
				totalprofit+=25
			elseif R[i] <= 700
				totalprofit+=20
			elseif R[i] <= 900
				totalprofit+=15
			elseif R[i] <= 1400
				totalprofit+=12
			elseif R[i] <= 1900
				totalprofit+=10
			elseif R[i] <= 2400
				totalprofit+=9
			elseif R[i] <= 3400
				totalprofit+=8
			elseif R[i] <= 5400
				totalprofit+=7
			elseif R[i] <= 8400
				totalprofit+=6
			elseif R[i] <= 14425
				totalprofit+=5
			end
		end
		totalprofit-= 3*num_lineups
    #print("\nMax lineup actual points = ",preal_max,"\n")
    #outfile = open(path_to_output, "w")
		if formulation == variance_covariance
    	outfile = open(string(myfolder,"baseball_variance_", mean_weight, var_weight, cov_weight,
			"_covariance_", stack_order[1],"_",stack_order[2],"_overlap_", num_overlap[1],"_",n0_overlap,"_lineups_", R[1], "_", nprofit, "_", totalprofit,".csv"), "w")
    	write(outfile, lineup2)
    	close(outfile)
		elseif formulation == stacking_non_consecutive_variance
			outfile = open(string(myfolder, "non_consec_var_", stack_order[1], "_overlap_", num_overlap[1], "_rank_", R[1], "_profit_", totalprofit, ".csv"), "w")
			write(outfile, lineup2)
			close(outfile)
		elseif formulation == stacking_non_consecutive_projections
			outfile = open(string(myfolder, "non_consec_proj_", stack_order[1], "_overlap_", num_overlap[1], "_rank_", R[1], "_profit_", totalprofit, ".csv"), "w")
			write(outfile, lineup2)
			close(outfile)
		else
			outfile = open(string(myfolder,"baseball_", string(formulation), "_", stack_order[1],"_",stack_order[2],"_overlap_", num_overlap[1],"_",n0_overlap,"_lineups_", R[1], "_", nprofit, "_", totalprofit,".csv"), "w")
	    write(outfile, lineup2)
	    close(outfile)
		end
		println("Top rank: ", R[1], "/", ncontest)
		println("Total profit: ", totalprofit)
    # return Preal
end


###############################################################################
###############################################################################
###############################################################################
###############################################################################
#INPUT PARAMS
#for i in 10:12

	#for i in [21:22; 25:30]
	global mean_weight = 1
	global var_weight = 1
	global cov_weight = 1

	num_lineups = 200 # num_lineups is the total number of lineups
	n0_overlap = num_lineups;
	num_overlap =[6*ones(n0_overlap,1); 7*ones(num_lineups-n0_overlap,1)]; # num_overlap is the maximum overlap of players
	stack_order = [4,1]; #size of each stack you want
	nstacks = [1,1];  #number of teams with each stack size

	formulation = stacking_non_consecutive_variance

	June1 = 7:12
	June2 = [13; 20:30]
	July = [1:3; 6; 15; 18:22; 25:31]
	August = [2; 3; 5; 8; 12; 15:18; 22; 26; 28:31]
	September = [2; 6; 13; 16; 19; 20; 26; 27]

for date in June1

	if date < 10
		folder_str = string("0", date)
	else
		folder_str = string(date)
	end

	myfolder_str = string(date)


	folder = string("C:/Users/Arjun Mithal/Dropbox (MIT)/FantasyBaseball/2016/2016-06-", folder_str, "\\")  #folder where the player projections are - this folder is named by the date of the contest
	myfolder = string("C:/Users/Arjun Mithal/Dropbox (MIT)/DraftKings/Fantasy Baseball/Previous Contests/2016.6.", myfolder_str, "\\")




	path_pitchers = string(myfolder,"dailyfantasynerd_players (1).csv") #path to the csv file with the players information (pitchers and hitters)
	path_hitters = string(myfolder,"dailyfantasynerd_players.csv")

	path_contest = searchdir(folder,"contest");
	path_to_ID= searchdir(folder,"DKSalaries");
	path_to_output= string(myfolder,"baseball_", string(formulation), "_projconst_stackorder_", stack_order[1],"_",stack_order[2],"_overlap_", num_overlap[1],"_",n0_overlap,"_lineups_",num_lineups,".csv"); # path_to_output is a string
                                        #that gives the path to the csv file that will give the outputted results

	print(path_to_output)


	##################################################################
	# Running the code
	println("Calculating DraftKings baseball linueps.\n\t",num_lineups, " lineups\n\t","Stack type ",formulation,
	"\n\tOverlap = ", num_overlap[1],"\n" )

	tic()

	create_lineups(num_lineups, num_overlap, path_pitchers,path_hitters, formulation, path_to_output,path_to_ID,stack_order,nstacks);
	telapsed = toq();


	###############################################
	#ANALYZE RESULTS


	println("Took ", telapsed/60.0, " minutes to calculate ", num_lineups, " lineups")

	println("DK Mafia 4 life")

end

for date in June2

	if date < 10
		folder_str = string("0", date)
	else
		folder_str = string(date)
	end

	myfolder_str = string(date)


	folder = string("C:/Users/Arjun Mithal/Dropbox (MIT)/FantasyBaseball/2016/2016-06-", folder_str, "\\")  #folder where the player projections are - this folder is named by the date of the contest
	myfolder = string("C:/Users/Arjun Mithal/Dropbox (MIT)/DraftKings/Fantasy Baseball/2016.6.", myfolder_str, "\\")




	path_pitchers = string(myfolder,"rdailyfantasynerd_players (1).csv") #path to the csv file with the players information (pitchers and hitters)
	path_hitters = string(myfolder,"rdailyfantasynerd_players.csv")

	path_contest = searchdir(folder,"contest");
	path_to_ID= searchdir(folder,"DKSalaries");
	path_to_output= string(myfolder,"baseball_", string(formulation), "_projconst_stackorder_", stack_order[1],"_",stack_order[2],"_overlap_", num_overlap[1],"_",n0_overlap,"_lineups_",num_lineups,".csv"); # path_to_output is a string
                                        #that gives the path to the csv file that will give the outputted results

	print(path_to_output)


	##################################################################
	# Running the code
	println("Calculating DraftKings baseball linueps.\n\t",num_lineups, " lineups\n\t","Stack type ",formulation,
	"\n\tOverlap = ", num_overlap[1],"\n" )

	tic()

	create_lineups(num_lineups, num_overlap, path_pitchers,path_hitters, formulation, path_to_output,path_to_ID,stack_order,nstacks);
	telapsed = toq();


	###############################################
	#ANALYZE RESULTS


	println("Took ", telapsed/60.0, " minutes to calculate ", num_lineups, " lineups")

	println("DK Mafia 4 life")

end

for date in July

	if date < 10
		folder_str = string("0", date)
	else
		folder_str = string(date)
	end

	myfolder_str = string(date)


	folder = string("C:/Users/Arjun Mithal/Dropbox (MIT)/FantasyBaseball/2016/2016-07-", folder_str, "\\")  #folder where the player projections are - this folder is named by the date of the contest
	myfolder = string("C:/Users/Arjun Mithal/Dropbox (MIT)/DraftKings/Fantasy Baseball/2016.7.", myfolder_str, "\\")




	path_pitchers = string(myfolder,"rdailyfantasynerd_players (1).csv") #path to the csv file with the players information (pitchers and hitters)
	path_hitters = string(myfolder,"rdailyfantasynerd_players.csv")

	path_contest = searchdir(folder,"contest");
	path_to_ID= searchdir(folder,"DKSalaries");
	path_to_output= string(myfolder,"baseball_", string(formulation), "_projconst_stackorder_", stack_order[1],"_",stack_order[2],"_overlap_", num_overlap[1],"_",n0_overlap,"_lineups_",num_lineups,".csv"); # path_to_output is a string
                                        #that gives the path to the csv file that will give the outputted results

	print(path_to_output)


	##################################################################
	# Running the code
	println("Calculating DraftKings baseball linueps.\n\t",num_lineups, " lineups\n\t","Stack type ",formulation,
	"\n\tOverlap = ", num_overlap[1],"\n" )

	tic()

	create_lineups(num_lineups, num_overlap, path_pitchers,path_hitters, formulation, path_to_output,path_to_ID,stack_order,nstacks);
	telapsed = toq();


	###############################################
	#ANALYZE RESULTS


	println("Took ", telapsed/60.0, " minutes to calculate ", num_lineups, " lineups")

	println("DK Mafia 4 life")

end

for date in August

	if date < 10
		folder_str = string("0", date)
	else
		folder_str = string(date)
	end

	myfolder_str = string(date)


	folder = string("C:/Users/Arjun Mithal/Dropbox (MIT)/FantasyBaseball/2016/2016-08-", folder_str, "\\")  #folder where the player projections are - this folder is named by the date of the contest
	myfolder = string("C:/Users/Arjun Mithal/Dropbox (MIT)/DraftKings/Fantasy Baseball/2016.8.", myfolder_str, "\\")




	path_pitchers = string(myfolder,"rdailyfantasynerd_players (1).csv") #path to the csv file with the players information (pitchers and hitters)
	path_hitters = string(myfolder,"rdailyfantasynerd_players.csv")

	path_contest = searchdir(folder,"contest");
	path_to_ID= searchdir(folder,"DKSalaries");
	path_to_output= string(myfolder,"baseball_", string(formulation), "_projconst_stackorder_", stack_order[1],"_",stack_order[2],"_overlap_", num_overlap[1],"_",n0_overlap,"_lineups_",num_lineups,".csv"); # path_to_output is a string
                                        #that gives the path to the csv file that will give the outputted results

	print(path_to_output)


	##################################################################
	# Running the code
	println("Calculating DraftKings baseball linueps.\n\t",num_lineups, " lineups\n\t","Stack type ",formulation,
	"\n\tOverlap = ", num_overlap[1],"\n" )

	tic()

	create_lineups(num_lineups, num_overlap, path_pitchers,path_hitters, formulation, path_to_output,path_to_ID,stack_order,nstacks);
	telapsed = toq();


	###############################################
	#ANALYZE RESULTS


	println("Took ", telapsed/60.0, " minutes to calculate ", num_lineups, " lineups")

	println("DK Mafia 4 life")

end

for date in September

	if date < 10
		folder_str = string("0", date)
	else
		folder_str = string(date)
	end

	myfolder_str = string(date)


	folder = string("C:/Users/Arjun Mithal/Dropbox (MIT)/FantasyBaseball/2016/2016-09-", folder_str, "\\")  #folder where the player projections are - this folder is named by the date of the contest
	myfolder = string("C:/Users/Arjun Mithal/Dropbox (MIT)/DraftKings/Fantasy Baseball/2016.9.", myfolder_str, "\\")




	path_pitchers = string(myfolder,"rdailyfantasynerd_players (1).csv") #path to the csv file with the players information (pitchers and hitters)
	path_hitters = string(myfolder,"rdailyfantasynerd_players.csv")

	path_contest = searchdir(folder,"contest");
	path_to_ID= searchdir(folder,"DKSalaries");
	path_to_output= string(myfolder,"baseball_", string(formulation), "_projconst_stackorder_", stack_order[1],"_",stack_order[2],"_overlap_", num_overlap[1],"_",n0_overlap,"_lineups_",num_lineups,".csv"); # path_to_output is a string
                                        #that gives the path to the csv file that will give the outputted results

	print(path_to_output)


	##################################################################
	# Running the code
	println("Calculating DraftKings baseball linueps.\n\t",num_lineups, " lineups\n\t","Stack type ",formulation,
	"\n\tOverlap = ", num_overlap[1],"\n" )

	tic()

	create_lineups(num_lineups, num_overlap, path_pitchers,path_hitters, formulation, path_to_output,path_to_ID,stack_order,nstacks);
	telapsed = toq();


	###############################################
	#ANALYZE RESULTS


	println("Took ", telapsed/60.0, " minutes to calculate ", num_lineups, " lineups")

	println("DK Mafia 4 life")

end
