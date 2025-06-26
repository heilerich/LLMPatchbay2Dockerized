/*
 * Cappuccino frontend for PatchbayLLM
 *
 * Created by daboe01 on Dec, 29, 2023 by Daniel Boehringer.
 * Copyright 2023, All rights reserved.
 *
 * Todo: bind label to block data in AppController so no reload is necessary after setting label name
 *
 *
 */



/////////////////////////////////////////////////////////

HostURL=""
BaseURL=HostURL+"/";

/////////////////////////////////////////////////////////

@import <Foundation/CPObject.j>
@import <Renaissance/Renaissance.j>
@import "TNGrowlCenter.j";
@import "TNGrowlView.j";
@import "LaceViewController.j";

@implementation FSArrayController(baseReloadFix)

- (void)fullyReloadAsync
{
    var entity = self._entity;
    entity._pkcache = [];
    [entity._store fetchObjectsForURLRequest:[entity._store requestForAddressingAllObjectsInEntity:entity] inEntity:entity requestDelegate:self._contentObject];
}

@end

@implementation CGPTURLRequest : CPURLRequest

- (id)initWithURL:(CPURL)anURL cachePolicy:(CPURLRequestCachePolicy)aCachePolicy timeoutInterval:(CPTimeInterval)aTimeoutInterval
{
    if (self = [super initWithURL:anURL initWithURL:anURL cachePolicy:aCachePolicy timeoutInterval:aTimeoutInterval])
    {
        [self setValue:"3037" forHTTPHeaderField:"X-ARGOS-ROUTING"];
    }

    return self;
}

@end

@implementation SessionStore : FSStore 

- (CPURLRequest)requestForAddressingObjectsWithKey: aKey equallingValue: (id) someval inEntity:(FSEntity) someEntity
{
    var request = [CGPTURLRequest requestWithURL: [self baseURL]+"/"+[someEntity name]+"/"+aKey+"/"+someval];

    return request;
}
-(CPURLRequest) requestForInsertingObjectInEntity:(FSEntity) someEntity
{
    var request = [CPURLRequest requestWithURL: [self baseURL]+"/"+[someEntity name]+"/"+ [someEntity pk]];
    [request setHTTPMethod:"POST"];

    return request;
}

- (CPURLRequest)requestForFuzzilyAddressingObjectsWithKey: aKey equallingValue: (id) someval inEntity:(FSEntity) someEntity
{
    var request = [CGPTURLRequest requestWithURL: [self baseURL]+"/"+[someEntity name]+"/"+aKey+"/like/"+someval];

    return request;
}

- (CPURLRequest)requestForAddressingAllObjectsInEntity:(FSEntity) someEntity
{
    var request = [CGPTURLRequest requestWithURL: [self baseURL]+"/"+[someEntity name] ];

    return request;
}

@end

@implementation AppController : CPObject
{
    id  store @accessors;

    id  mainWindow;
    id  addBlocksWindow;
    id  editWindow;
    id  laceView;
    id  inputWindow;
    id  inputText;

    id  laceViewController;
    id  projectsController
    id  inputController
    id  outputController
    id  blocksCatalogueController @accessors;
    id  blocksController @accessors;
    id  settingsController @accessors;
    id  globalsController @accessors;
    id  blockIndex;
    id  connections;
    id  addBlocksPopover;
    id  editPopover;
    id  runConnection;
    id  spinnerImg;

    id embeddingModelsController;
    id embeddedDatasetsController;
    id embeddedDataController;
    id importCSVText;
    
    id  _searchTerm @accessors(property=searchTerm);
    id  _playgroundSearchTerm @accessors(property=playgroundSearchTerm);

}

- (void)flushGUI
{
    var fr = [[CPApp keyWindow] firstResponder];

    if ([fr respondsToSelector:@selector(_reverseSetBinding)])
        [fr _reverseSetBinding]; // flush any typed text before printing


    if ([fr isKindOfClass:CPDatePicker])
        [fr resignFirstResponder]; // important for the textual datepicker to work properly
}

- (void)setSearchTerm:(id)aTerm
{
    if (aTerm && aTerm.length)
        [embeddedDataController setFilterPredicate:[CPPredicate predicateWithFormat:"payload CONTAINS[cd] %@ or label = %@", aTerm, aTerm]];
    else
        [embeddedDataController setFilterPredicate:nil];
}

- (void)setPlaygroundSearchTerm:(id)aTerm
{
    if (aTerm && aTerm.length)
        [inputController setFilterPredicate:[CPPredicate predicateWithFormat:"content CONTAINS[cd] %@ or title CONTAINS[cd] %@", aTerm, aTerm]];
    else
        [inputController setFilterPredicate:nil];
}

-(void)setButtonBusy:(CPButton)myButton
{
    myButton._oldImage = [myButton image];
    [myButton setImage:spinnerImg];
    [myButton setValue:spinnerImg forThemeAttribute:@"image" inState:CPThemeStateDisabled];
    [myButton setEnabled:NO];
}
-(void)resetButtonBusy:(CPButton)myButton
{
    [myButton setImage:myButton._oldImage];
    [myButton setEnabled:YES];
}

- (void)performImportCSV:(id)sender suffix:(CPString)suffix
{
    var myreq = [CPURLRequest requestWithURL:"/LLM/import_embedding_dataset/" + [embeddedDatasetsController valueForKeyPath:"selection.id"] + suffix];
    [myreq setHTTPMethod:"POST"];
    [myreq setHTTPBody:[importCSVText stringValue]];
    [CPURLConnection connectionWithRequest:myreq delegate:nil];

    [importCSVText setString:'']; // fixme: better gui feedback
}

- (void)performImportCSV:(id)sender
{
    [self performImportCSV:sender suffix:""];
}

- (void)performImportCSVAppend:(id)sender
{
    [self performImportCSV:sender suffix:"?preserve=1"];
}

- (void)performImportCSVRemove:(id)sender
{
    [self performImportCSV:sender suffix:"?remove=1"];
}

-(void)openWindowWithURL:(CPString)myURL inWindowID:(CPString)myid
{
    // window.removeEventListener('beforeunload', beforeUnloadHandler);
    window.open(myURL, myid);
    // window.addEventListener('beforeunload', beforeUnloadHandler);
}

- (void)downloadDataset:(id)sender
{
    [self openWindowWithURL:'/LLM/get_data_from_dataset/' + [embeddedDatasetsController valueForKeyPath:'selection.name'] inWindowID:'download_window'];
}

- (void)duplicatePrompt:(id)sender
{
    var myreq = [CPURLRequest requestWithURL:"/LLM/duplicate_prompt/" + [projectsController valueForKeyPath:"selection.id"]];
    [myreq setHTTPMethod:"POST"];
    var connection = [CPURLConnection connectionWithRequest:myreq delegate:self];
    [self setButtonBusy:sender];
    connection._senderButton = sender;
}

- (void)run:(id)sender
{
    [self flushGUI];

    setTimeout(function(){

        var myreq = [CPURLRequest requestWithURL:"/LLM/run/" + [inputController valueForKeyPath:"selection.id"]
                                     cachePolicy:CPURLRequestReloadIgnoringLocalCacheData timeoutInterval:500000];
        [myreq setHTTPMethod:"POST"];
        runConnection = [CPURLConnection connectionWithRequest:myreq delegate:self];

        [self setButtonBusy:sender]
        runConnection._senderButton = sender;
    }, 250);
}

- (void)insertInput:(id)sender
{
    [inputController insert:sender]
    [inputWindow makeKeyAndOrderFront:sender]
    [inputText selectAll:sender]
}

- (void)removeInput:(id)sender
{
    [inputController remove:sender]
}

- (void)removeBlocks:(id)sender
{
    [laceViewController removeBlocks:sender]
}

- (void)addBlocks:(id)sender
{
    [laceViewController addBlocks:sender]
}

- (void)performAddBlocks:(id)sender
{
    [laceViewController performAddBlocks:sender]
}

- (void)connection:(CPConnection)someConnection didReceiveData:(CPData)data
{
    if (someConnection._senderButton && [someConnection._senderButton isKindOfClass:CPButton])
        [self resetButtonBusy:someConnection._senderButton];

    if ([[[someConnection currentRequest] URL] absoluteString].indexOf("/LLM/duplicate_prompt/") >= 0)
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Success" message:@"Prompt duplicated." customIcon:TNGrowlIconInfo];
        [projectsController reload];
        return;
    }

    var result = JSON.parse(data);

    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Result" message:result['result'] customIcon:TNGrowlIconInfo];

    [outputController reload];
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    store = [[SessionStore alloc] initWithBaseURL:HostURL+"/LLM"];

    [CPBundle loadRessourceNamed:"model.gsmarkup" owner:self];
    [CPBundle loadRessourceNamed:"gui.gsmarkup" owner:self];
    spinnerImg = [[CPImage alloc] initWithContentsOfFile:[CPString stringWithFormat:@"%@%@", [[CPBundle mainBundle] resourcePath], "spinner.gif"]];

    [[TNGrowlCenter defaultCenter] setView:[[CPApp mainWindow] contentView]];
    [[TNGrowlCenter defaultCenter] setLifeDefaultTime:10];

    [[mainWindow contentView] setBackgroundColor:[CPColor colorWithWhite:0.95 alpha:1.0]];

     laceViewController = [LaceViewController new];
    [laceViewController setView:laceView];
    [laceViewController setBlocksController:blocksController];
    [laceViewController setSettingsController:settingsController];
    [laceViewController setEditWindow:editWindow];
    [laceViewController setAddBlocksView:[addBlocksWindow contentView]];

}

@end
