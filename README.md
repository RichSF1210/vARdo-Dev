# vARdo-Dev
vARDo - Code exploration in Swift 

I have been thinking about the crux of the ARplane and parsing that info to Pd.

I have been thinking about the logic of this:

1 - detects ARplane 
2 - established sides length 
3 - parse ‘side’ data into Pd 
4 - Pd makes sounds based on values sent 
5 - sides and dimensions are x,y,z and height available 

This made me think, 

if the ARplane is detected would it just send the sides once, then they remain as a constant for example ‘table’ 
Are they sent as a whole? Averaged or separate sides
If the side values are sent are they sent simultaneously or async
If the side as sent async then what side first
If there are sides then should be nearest side to user first 
If this is sent once then how could this be repeated over time at a set rate. 
If the sides are decided async then could they have a set rate also

These factors i tried to code in swift, i'm unsure if this is useful to you in terms of my logic but thought i would parse it on

These swift files go in order of complexity. VardoCodeExploration.swift is the first file, the comments are populated in code and the main script ideas at the top of each swift file also 
